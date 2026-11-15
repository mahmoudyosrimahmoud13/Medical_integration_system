"""Rich demo data, so the apps look alive on first run.

    python -m app.seed --demo       runs seed_reference + seed_admin + this module

Creates (only if missing): 165 Egyptian-market products, 20 doctors in 9 governorates, 5 hospitals,
9 pharmacies with stock, 35 patients, a customer support account, applications waiting for the admin,
past and upcoming appointments, medical records with prescriptions, reviews, notifications and
conversations between every kind of user. All demo passwords are <Role>@12345 (e.g. Doctor@12345).
"""

import csv
import random
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import BASE_DIR
from app.core.security import hash_password
from app.models import (
    Appointment,
    Area,
    Disease,
    Doctor,
    DoctorSchedule,
    Drug,
    Governorate,
    Hospital,
    HospitalDoctor,
    MedicalSession,
    Notification,
    NotificationType,
    Pharmacy,
    PharmacyDrug,
    Prescription,
    Product,
    Review,
    Role,
    Specialty,
    User,
    UserRole,
)
from app.models.chat import ChatMessage
from app.services.chat import start_or_get

SEED_DIR = BASE_DIR / "seed_data"
rng = random.Random(55)  # fixed seed: the same demo every time

DOCTORS = [
    # name, email, specialty, governorate, area, college, price, gender_male, summary
    ("Ahmed Hassan", "doctor@healthhub.local", "Cardiology", "Cairo", "Maadi", "Cairo University", 400, True, "Consultant cardiologist, 15 years in interventional cardiology at Kasr Al Ainy."),
    ("Mona El Sayed", "mona.elsayed@healthhub.local", "Dermatology", "Cairo", "New Heliopolis", "Ain Shams University", 350, False, "Dermatology and cosmetic procedures. Special interest in acne and pigmentation."),
    ("Khaled Mostafa", "khaled.mostafa@healthhub.local", "Orthopaedics", "Giza", "Dokki", "Cairo University", 450, True, "Orthopaedic surgeon, sports injuries and joint replacement."),
    ("Yasmin Fouad", "yasmin.fouad@healthhub.local", "Paediatrics", "Cairo", "Nasr City", "Ain Shams University", 300, False, "Paediatrician. Newborn care, vaccination schedules and growth follow-up."),
    ("Omar Abdelrahman", "omar.abdel@healthhub.local", "Internal medicine", "Alexandria", "Smouha", "Alexandria University", 300, True, "Internal medicine with a focus on diabetes and hypertension."),
    ("Nour Ibrahim", "nour.ibrahim@healthhub.local", "Obstetrics and gynaecology", "Cairo", "Zamalek", "Cairo University", 500, False, "Obstetrics, high-risk pregnancy follow-up and women's health."),
    ("Mahmoud Adel", "mahmoud.adel@healthhub.local", "Neurology", "Giza", "Mohandessin", "Cairo University", 450, True, "Neurologist. Headache clinic, epilepsy and stroke follow-up."),
    ("Dina Samir", "dina.samir@healthhub.local", "Psychiatry", "Cairo", "New Cairo", "Ain Shams University", 500, False, "Psychiatrist and psychotherapist. Anxiety, depression and sleep."),
    ("Tarek Nabil", "tarek.nabil@healthhub.local", "Ophthalmology", "Alexandria", "Sidi Gaber", "Alexandria University", 350, True, "Ophthalmologist, cataract and refractive surgery."),
    ("Heba Mahmoud", "heba.mahmoud@healthhub.local", "Endocrinology", "Cairo", "Maadi", "Cairo University", 400, False, "Endocrinologist. Thyroid, diabetes and hormones."),
    ("Amr Lotfy", "amr.lotfy@healthhub.local", "Gastroenterology", "Giza", "Mohandessin", "Cairo University", 450, True, "Gastroenterology and endoscopy. Liver and IBS clinic."),
    ("Salma Youssef", "salma.youssef@healthhub.local", "General practice", "Cairo", "Shubra", "Ain Shams University", 200, False, "Family doctor. First stop for the whole family."),
    ("Mostafa Gaber", "mostafa.gaber@healthhub.local", "Urology", "Dakahlia", "Mansoura", "Mansoura University", 350, True, "Urologist. Kidney stones and prostate clinic."),
    ("Ranya Hegazy", "ranya.hegazy@healthhub.local", "Nephrology", "Dakahlia", "Mansoura", "Mansoura University", 400, False, "Nephrologist. Chronic kidney disease and dialysis follow-up."),
    ("Ibrahim Soliman", "ibrahim.soliman@healthhub.local", "Otorhinolaryngology", "Gharbiya", "Tanta", "Tanta University", 300, True, "ENT surgeon. Sinus, tonsils and hearing problems."),
    ("Asmaa Rashad", "asmaa.rashad@healthhub.local", "Respiratory medicine", "Sharkia", "Zagazig", "Zagazig University", 300, False, "Chest physician. Asthma, COPD and sleep apnoea."),
    ("Hany Abdallah", "hany.abdallah@healthhub.local", "Rheumatology", "Assiut", "Assiut", "Assiut University", 300, True, "Rheumatologist. Arthritis, lupus and gout."),
    ("Marwa Saeed", "marwa.saeed@healthhub.local", "Dental, oral and maxillo-facial surgery", "Cairo", "Mokattam", "Cairo University", 250, False, "Dentist. Fillings, root canals and children's dentistry."),
    ("Walid Hamed", "walid.hamed@healthhub.local", "Physical medicine and rehabilitation", "Red Sea", "Hurghada", "Ain Shams University", 300, True, "Physiotherapy and rehabilitation after injuries and surgery."),
    ("Noha Fawzy", "noha.fawzy@healthhub.local", "Obstetrics and gynaecology", "Ismailia", "Ismailia", "Suez Canal University", 350, False, "Gynaecologist. Pregnancy follow-up and fertility."),
]

# doctors who applied and wait for the admin's decision (Admin > Requests)
PENDING_DOCTORS = [
    ("Adham Shawky", "adham.shawky@healthhub.local", "Cardiology", "Luxor", "Luxor", "Assiut University", 300, True, "Cardiology specialist, 6 years in Luxor."),
    ("Shaimaa Lotfi", "shaimaa.lotfi@healthhub.local", "Dermatology", "Port Said", "Port Fouad", "Suez Canal University", 250, False, "Dermatologist. Hair loss and skin allergies."),
]

HOSPITALS = [
    ("Dar El Shifa Hospital", "hospital@healthhub.local", "Cairo", "Nasr City", "1 Ramses St.", "0221234567", "General hospital with 24/7 emergency, ICU and surgery.", [(0, "Cardiology"), (3, "Paediatrics"), (6, "Neurology"), (9, "Endocrinology")]),
    ("Nile Medical Center", "nile.medical@healthhub.local", "Giza", "Dokki", "22 Tahrir St.", "0233456789", "Multi-specialty day clinics and imaging.", [(2, "Orthopaedics"), (10, "Gastroenterology"), (1, "Dermatology")]),
    ("Alexandria Care Hospital", "alex.care@healthhub.local", "Alexandria", "Smouha", "15 Fawzy Moaz St.", "0345678901", "Teaching hospital on the north coast.", [(4, "Internal medicine"), (8, "Ophthalmology")]),
    ("Delta Kidney Center", "delta.kidney@healthhub.local", "Dakahlia", "Mansoura", "3 Gomhoria St.", "0502223344", "Urology, nephrology and dialysis for the Delta.", [(12, "Urology"), (13, "Nephrology"), (15, "Chest")]),
    ("Upper Egypt Medical Center", "upper.egypt@healthhub.local", "Assiut", "Assiut", "10 Nile Corniche", "0882334455", "Day clinics, X-ray and physiotherapy.", [(16, "Rheumatology"), (14, "ENT"), (18, "Rehabilitation")]),
]

# a hospital and a pharmacy that applied and wait for the admin (Admin > Requests)
PENDING_HOSPITALS = [
    ("Red Sea Family Clinic", "redsea.clinic@healthhub.local", "Red Sea", "Hurghada", "Sheraton Rd.", "0653445566", "Family clinic for residents and visitors."),
]

PHARMACIES = [
    ("El Nour Pharmacy", "pharmacy@healthhub.local", "Cairo", "Maadi", "5 Nile St., Maadi", "0225551234"),
    ("El Ezaby Pharmacy, Heliopolis", "ezaby.helio@healthhub.local", "Cairo", "New Heliopolis", "34 El Thawra St.", "0226445566"),
    ("Seif Pharmacy, Nasr City", "seif.nasr@healthhub.local", "Cairo", "Nasr City", "12 Abbas El Akkad St.", "0222738899"),
    ("19011 Pharmacy, Dokki", "19011.dokki@healthhub.local", "Giza", "Dokki", "7 Mossadak St.", "19011"),
    ("Roshdy Pharmacy, Smouha", "roshdy.smouha@healthhub.local", "Alexandria", "Smouha", "40 Victor Emmanuel Sq.", "0334201122"),
    ("Misr Pharmacy, Zamalek", "misr.zamalek@healthhub.local", "Cairo", "Zamalek", "9 Brazil St.", "0227351199"),
    ("Al Shifa Pharmacy, Mansoura", "shifa.mansoura@healthhub.local", "Dakahlia", "Mansoura", "18 El Gaish St.", "0502115566"),
    ("Tanta Central Pharmacy", "tanta.central@healthhub.local", "Gharbiya", "Tanta", "2 El Bahr St.", "0403332211"),
    ("Nile Pharmacy, Assiut", "nile.assiut@healthhub.local", "Assiut", "Assiut", "25 Yousry Ragheb St.", "0882445566"),
]

PENDING_PHARMACIES = [
    ("Hurghada Marina Pharmacy", "marina.pharmacy@healthhub.local", "Red Sea", "Hurghada", "Marina Blvd.", "0653556677"),
]

SUPPORT = ("Mai Salah", "support@healthhub.local", "Support@12345")

PATIENT_NAMES = [
    ("Sara Ali", False), ("Mohamed Farouk", True), ("Laila Hamdy", False), ("Youssef Kamal", True), ("Nadia Salem", False),
    ("Karim Mansour", True), ("Rania Gamal", False), ("Hossam Fathy", True), ("Mariam Zaki", False), ("Ali Sherif", True),
    ("Aya Magdy", False), ("Sherif Ragab", True), ("Hana Tawfik", False), ("Mostafa Ezzat", True), ("Farida Nasser", False),
    ("Ziad Hesham", True), ("Nourhan Adly", False), ("Bassem Wagdy", True), ("Reem Anwar", False), ("Hassan Mourad", True),
    ("Eman Saber", False), ("Ahmed Shaker", True), ("Doaa Fekry", False), ("Islam Hamdi", True), ("Yara Osama", False),
    ("Tamer Helmy", True), ("Ghada Ashraf", False), ("Khaled Ezz", True), ("Salma Hatem", False), ("Omar Nagy", True),
    ("Habiba Wael", False), ("Adel Rizk", True), ("Malak Yehia", False), ("Seif Emad", True), ("Rehab Kamel", False),
]

PATIENT_PLACES = [("Cairo", "Maadi"), ("Cairo", "Nasr City"), ("Cairo", "New Heliopolis"), ("Giza", "Dokki"), ("Alexandria", "Smouha"),
                  ("Cairo", "New Cairo"), ("Dakahlia", "Mansoura"), ("Gharbiya", "Tanta"), ("Sharkia", "Zagazig"), ("Assiut", "Assiut")]

# Sara Ali (patient@healthhub.local) always has the same history, so the demo always shows the same things:
# blood pressure, diabetes and atrial fibrillation, on warfarin (the interaction check has something to find).
MAIN_PATIENT_HISTORY = [
    # condition, doctor index, days ago, [(ingredient, repeat, note)]
    ("Hypertension", 0, 120, [("bisoprolol", "daily", "before breakfast"), ("amlodipine", "daily", "at night")]),
    ("Type 2 diabetes", 9, 60, [("metformin", "every 12 hours", "after food")]),
    ("Atrial fibrillation", 0, 30, [("warfarin", "daily", "same time every evening, avoid aspirin")]),
]

# condition -> (specialty that treats it, ingredients typically prescribed)
CONDITIONS = {
    "Hypertension": ("Cardiology", ["bisoprolol", "amlodipine", "losartan"]),
    "Type 2 diabetes": ("Endocrinology", ["metformin", "glimepiride", "empagliflozin"]),
    "Hyperlipidaemia": ("Cardiology", ["atorvastatin", "rosuvastatin"]),
    "Acute tonsillitis": ("General practice", ["amoxicillin", "acetaminophen"]),
    "Lower back pain": ("Orthopaedics", ["diclofenac", "meloxicam"]),
    "Acne vulgaris": ("Dermatology", ["doxycycline", "clotrimazole"]),
    "Migraine": ("Neurology", ["ibuprofen", "amitriptyline"]),
    "Generalised anxiety": ("Psychiatry", ["escitalopram", "sertraline"]),
    "GERD": ("Gastroenterology", ["pantoprazole", "domperidone"]),
    "Hypothyroidism": ("Endocrinology", ["levothyroxine"]),
    "Allergic rhinitis": ("General practice", ["cetirizine", "mometasone"]),
    "Urinary tract infection": ("Internal medicine", ["ciprofloxacin", "nitrofurantoin"]),
    "Asthma": ("Paediatrics", ["salbutamol", "montelukast"]),
    "Atrial fibrillation": ("Cardiology", ["rivaroxaban", "bisoprolol"]),
    "Gout": ("Internal medicine", ["allopurinol", "colchicine"]),
}

CHATS = [
    ("patient", 0, 0, "Appointment question", [
        ("p", "Hello doctor, should I stop my blood pressure pills before the visit?"),
        ("d", "Hello Sara. No, keep taking them as usual and bring the box with you."),
        ("p", "Thank you, see you Monday."),
    ]),
    ("patient", 1, 4, "Blood test results", [
        ("p", "Doctor, my fasting sugar was 165 this morning. Is that bad?"),
        ("d", "It is higher than we want. Keep the Glucophage dose and let's check HbA1c before the next visit."),
    ]),
    ("pharmacy", 2, 0, "Stock question", [
        ("p", "Do you have Concor 5 mg in stock?"),
        ("ph", "Yes, we have it. 90 EGP, open until 11 pm."),
    ]),
    ("hospital", 0, 0, "Cardiology schedule", [
        ("h", "Dr. Ahmed, the cardiology clinic moves to the 3rd floor from next week."),
        ("d", "Noted, thank you. Please tell reception to redirect my patients."),
    ]),
    ("pharmacy", 0, 0, "Warfarin refill", [
        ("p", "Hi, I need Marevan 5 mg again. Do you have it?"),
        ("ph", "Yes, 3 boxes left. Please bring your prescription code from the app."),
        ("p", "Great, I'll come after work."),
    ]),
    # two doctors at the same hospital (Dar El Shifa)
    ("colleague", 0, 9, "Shared patient", [
        ("a", "Dr. Heba, Sara Ali's HbA1c came back at 7.9. Should we add something to metformin?"),
        ("b", "I'll see her next week and consider empagliflozin. Thanks for the heads up."),
    ]),
    # customer support helping a patient
    ("support", 3, 0, "Uploading a CT scan", [
        ("p", "The upload keeps failing for my CT scan file."),
        ("s", "Hi Youssef, files must be under 10 MB. Try exporting the scan as JPG, or send it in two parts."),
        ("p", "That worked, thank you!"),
    ]),
]


async def _area(db: AsyncSession, gov: str, area: str) -> Area:
    row = await db.scalar(select(Area).join(Governorate).where(Governorate.key == gov, Area.key == area))
    if row is None:  # the dataset may file the area under another governorate; exact name wins
        row = await db.scalar(select(Area).where(Area.key == area).limit(1))
    if row is None:  # last resort: any area in that governorate
        row = await db.scalar(select(Area).join(Governorate).where(Governorate.key == gov).order_by(Area.key).limit(1))
    return row


async def _specialty(db: AsyncSession, name: str) -> Specialty:
    row = await db.scalar(select(Specialty).where(func.lower(Specialty.name) == name.lower()))
    if row is None:
        row = Specialty(name=name)
        db.add(row)
        await db.flush()
    return row


async def _user(db: AsyncSession, *, email: str, password: str, name: str, roles: list[Role], area: Area | None, phone: str, national_id: str, male: bool, birth: date) -> User:
    user = await db.scalar(select(User).where(User.email == email))
    if user:
        return user
    user = User(
        email=email, username=email.split("@")[0], password_hash=hash_password(password), name=name, phone=phone,
        national_id=national_id, birth_date=birth, gender_male=male, area_id=area.id if area else None,
        email_confirmed=True, roles=[UserRole(role=r) for r in roles],
    )
    db.add(user)
    await db.flush()
    return user


def _nid(n: int, birth: date) -> str:
    century = "2" if birth.year < 2000 else "3"
    return f"{century}{birth.strftime('%y%m%d')}01{n:05d}"


async def seed_products(db: AsyncSession) -> int:
    if await db.scalar(select(func.count()).select_from(Product)):
        return 0
    by_name = {d.name.lower(): d.id for d in (await db.scalars(select(Drug))).all()}
    count = 0
    with open(SEED_DIR / "egypt_products.csv", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            drug_id = by_name.get(r["active_ingredient"].lower())
            if not drug_id:
                continue
            db.add(Product(
                brand=r["brand"], drug_id=drug_id, strength=r["strength"], form=r["form"], pack=r["pack"],
                manufacturer=r["manufacturer"], category=r["category"], price_egp=Decimal(r["price_egp"]),
                prescription_only=r["rx"] == "1",
            ))
            count += 1
    await db.commit()
    return count


async def seed_demo(db: AsyncSession) -> None:
    products = await seed_products(db)
    if await db.scalar(select(func.count()).select_from(Doctor)) and await db.scalar(select(func.count()).select_from(Appointment)):
        print("Demo data already present, skipping")
        return

    now = datetime.now(timezone.utc)
    today = date.today()

    # ---- doctors
    doctors: list[Doctor] = []
    for i, (name, email, spec, gov, area_name, college, price, male, summary) in enumerate(DOCTORS):
        area = await _area(db, gov, area_name)
        user = await _user(db, email=email, password="Doctor@12345", name=name, roles=[Role.PATIENT, Role.DOCTOR], area=area,
                           phone=f"0100{1000000 + i:07d}", national_id=_nid(100 + i, date(1980 + i % 10, 3, 1 + i)), male=male, birth=date(1980 + i % 10, 3, 1 + i))
        doctor = await db.scalar(select(Doctor).where(Doctor.user_id == user.id))
        if doctor is None:
            doctor = Doctor(
                user_id=user.id, specialty_id=(await _specialty(db, spec)).id, area_id=area.id, college_name=college,
                summary_career=summary, address_description=f"{rng.randint(2, 60)} {area_name} St.", accepted=True,
                price_session=Decimal(price), date_of_join=now - timedelta(days=rng.randint(30, 900)), graduation_year=date(2005 + i % 8, 6, 1),
            )
            db.add(doctor)
            await db.flush()
            if i == 0:  # the main demo doctor keeps a predictable week (tests and docs rely on it)
                days, start, length = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"], 9, 8
            else:
                days = rng.sample(["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"], k=rng.choice([3, 4, 5]))
                start, length = rng.choice([9, 10, 12, 14]), rng.choice([5, 6, 8])
            for d in days:
                db.add(DoctorSchedule(doctor_id=doctor.id, day_name=d, time_from=time(start), time_to=time(min(start + length, 22))))
        doctors.append(doctor)
    await db.flush()

    # ---- hospitals
    for i, (hname, email, gov, area_name, address, phone, desc, staff) in enumerate(HOSPITALS):
        area = await _area(db, gov, area_name)
        owner = await _user(db, email=email, password="Hospital@12345", name=f"{hname} Manager", roles=[Role.PATIENT, Role.HOSPITAL], area=area,
                            phone=f"0150{2000000 + i:07d}", national_id=_nid(200 + i, date(1975, 5, 5 + i)), male=True, birth=date(1975, 5, 5 + i))
        if await db.scalar(select(Hospital).where(Hospital.owner_id == owner.id)) is None:
            h = Hospital(owner_id=owner.id, name=hname, area_id=area.id, address_description=address, phone=phone, description=desc, accepted=True)
            db.add(h)
            await db.flush()
            for doc_index, dept in staff:
                db.add(HospitalDoctor(hospital_id=h.id, doctor_id=doctors[doc_index].id, department=dept))
    await db.flush()

    # ---- pharmacies with stock
    all_products = (await db.scalars(select(Product))).all()
    for i, (pname, email, gov, area_name, address, phone) in enumerate(PHARMACIES):
        area = await _area(db, gov, area_name)
        owner = await _user(db, email=email, password="Pharmacy@12345", name=f"{pname} Owner", roles=[Role.PATIENT, Role.PHARMACY], area=area,
                            phone=f"0120{3000000 + i:07d}", national_id=_nid(300 + i, date(1985, 7, 7 + i)), male=i % 2 == 0, birth=date(1985, 7, 7 + i))
        if await db.scalar(select(Pharmacy).where(Pharmacy.owner_id == owner.id)) is None:
            ph = Pharmacy(owner_id=owner.id, name=pname, area_id=area.id, address_description=address, phone=phone, accepted=True)
            db.add(ph)
            await db.flush()
            # each pharmacy stocks ~70% of ingredients, priced from the product list with a small spread
            seen = set()
            if i == 0:
                for drug_id, qty, price in [("DB00316", 120, 25), ("DB01050", 80, 40), ("DB00682", 30, 95)]:
                    seen.add(drug_id)
                    db.add(PharmacyDrug(pharmacy_id=ph.id, drug_id=drug_id, quantity=qty, price=Decimal(price)))
            for p in rng.sample(all_products, k=int(len(all_products) * .7)):
                if p.drug_id in seen:
                    continue
                seen.add(p.drug_id)
                qty = rng.choice([0, 0, 3, 6, 12, 25, 40, 80, 120])
                db.add(PharmacyDrug(pharmacy_id=ph.id, drug_id=p.drug_id, quantity=qty, price=Decimal(str(round(float(p.price_egp) * rng.uniform(.95, 1.1), 2)))))
    await db.flush()

    # ---- applications waiting for the admin
    for i, (name, email, spec, gov, area_name, college, price, male, summary) in enumerate(PENDING_DOCTORS):
        area = await _area(db, gov, area_name)
        user = await _user(db, email=email, password="Doctor@12345", name=name, roles=[Role.PATIENT], area=area,
                           phone=f"0100{1500000 + i:07d}", national_id=_nid(150 + i, date(1988, 4, 4 + i)), male=male, birth=date(1988, 4, 4 + i))
        if await db.scalar(select(Doctor).where(Doctor.user_id == user.id)) is None:
            db.add(Doctor(user_id=user.id, specialty_id=(await _specialty(db, spec)).id, area_id=area.id, college_name=college,
                          summary_career=summary, address_description=f"{rng.randint(2, 60)} {area_name} St.", accepted=False,
                          price_session=Decimal(price), graduation_year=date(2014, 6, 1)))
    for i, (hname, email, gov, area_name, address, phone, desc) in enumerate(PENDING_HOSPITALS):
        area = await _area(db, gov, area_name)
        owner = await _user(db, email=email, password="Hospital@12345", name=f"{hname} Manager", roles=[Role.PATIENT], area=area,
                            phone=f"0150{2500000 + i:07d}", national_id=_nid(250 + i, date(1979, 2, 2 + i)), male=False, birth=date(1979, 2, 2 + i))
        if await db.scalar(select(Hospital).where(Hospital.owner_id == owner.id)) is None:
            db.add(Hospital(owner_id=owner.id, name=hname, area_id=area.id, address_description=address, phone=phone, description=desc, accepted=False))
    for i, (pname, email, gov, area_name, address, phone) in enumerate(PENDING_PHARMACIES):
        area = await _area(db, gov, area_name)
        owner = await _user(db, email=email, password="Pharmacy@12345", name=f"{pname} Owner", roles=[Role.PATIENT], area=area,
                            phone=f"0120{3500000 + i:07d}", national_id=_nid(350 + i, date(1990, 9, 9 + i)), male=True, birth=date(1990, 9, 9 + i))
        if await db.scalar(select(Pharmacy).where(Pharmacy.owner_id == owner.id)) is None:
            db.add(Pharmacy(owner_id=owner.id, name=pname, area_id=area.id, address_description=address, phone=phone, accepted=False))

    # ---- customer support
    sname, semail, spass = SUPPORT
    support = await _user(db, email=semail, password=spass, name=sname, roles=[Role.CUSTOMER_SERVICE], area=await _area(db, "Cairo", "Maadi"),
                          phone="01009999999", national_id=_nid(999, date(1994, 1, 15)), male=False, birth=date(1994, 1, 15))
    await db.flush()

    # ---- patients
    patients: list[User] = []
    for i, (name, _) in enumerate(PATIENT_NAMES):
        male = PATIENT_NAMES[i][1]
        email = "patient@healthhub.local" if i == 0 else f"{name.lower().replace(' ', '.')}@healthhub.local"
        gov, area_name = rng.choice(PATIENT_PLACES)
        birth = date(1950 + rng.randint(0, 55), rng.randint(1, 12), rng.randint(1, 28))
        patients.append(await _user(db, email=email, password="Patient@12345", name=name, roles=[Role.PATIENT], area=await _area(db, gov, area_name),
                                    phone=f"0111{4000000 + i:07d}", national_id=_nid(400 + i, birth), male=male, birth=birth))
    await db.flush()

    # reload doctors so specialty and schedule relationships are available
    await db.commit()
    ids = [d.id for d in doctors]
    fresh = {d.id: d for d in (await db.scalars(select(Doctor).where(Doctor.id.in_(ids)).execution_options(populate_existing=True))).all()}
    doctors = [fresh[i] for i in ids]

    # ---- medical history: 1 to 3 conditions per patient, each with a session and prescriptions
    drugs_by_name = {d.name.lower(): d for d in (await db.scalars(select(Drug))).all()}
    doctors_by_spec = {}
    for d in doctors:
        doctors_by_spec.setdefault(d.specialty.name, []).append(d)
    for main_cond, doc_i, days_ago, meds in MAIN_PATIENT_HISTORY:
        p, doctor, when = patients[0], doctors[doc_i], now - timedelta(days=days_ago)
        db.add(Disease(patient_id=p.id, name=main_cond, persistent=True, cured=False, responsible_doctor_id=doctor.id))
        session = MedicalSession(doctor_id=doctor.id, patient_id=p.id, session_date=when, disease_name=main_cond, notes="Follow up every 3 months.")
        db.add(session)
        await db.flush()
        for ing, repeat, note in meds:
            drug = drugs_by_name.get(ing)
            if drug:
                db.add(Prescription(session_id=session.id, drug_id=drug.id, repeat=repeat, repeat_count=1, note=note,
                                    start_date=when.date(), end_date=when.date() + timedelta(days=3650)))
        db.add(Appointment(patient_id=p.id, doctor_id=doctor.id, day=when.date(), time_from=time(10), status="done"))
    for p in patients[1:]:
        for cond in rng.sample(list(CONDITIONS), k=rng.choice([1, 2, 2, 3])):
            spec, ingredients = CONDITIONS[cond]
            doctor = rng.choice(doctors_by_spec.get(spec) or doctors)
            chronic = cond in ("Hypertension", "Type 2 diabetes", "Hyperlipidaemia", "Hypothyroidism", "Asthma", "Atrial fibrillation", "Migraine", "GERD")
            when = now - timedelta(days=rng.randint(10, 400))
            db.add(Disease(patient_id=p.id, name=cond, persistent=chronic, cured=not chronic and rng.random() < .7, responsible_doctor_id=doctor.id))
            session = MedicalSession(doctor_id=doctor.id, patient_id=p.id, session_date=when, disease_name=cond,
                                     notes=rng.choice(["Follow up in 4 weeks.", "Lifestyle advice given.", "Labs requested.", None]))
            db.add(session)
            await db.flush()
            for ing in ingredients:
                drug = drugs_by_name.get(ing)
                if not drug:
                    continue
                days = 3650 if chronic else rng.choice([5, 7, 10, 14])
                db.add(Prescription(session_id=session.id, drug_id=drug.id, repeat=rng.choice(["daily", "every 12 hours", "every 8 hours"]),
                                    repeat_count=1, note=rng.choice(["after food", "before breakfast", "at night", None]),
                                    start_date=when.date(), end_date=when.date() + timedelta(days=days)))
            # a past appointment that led to the session, and a review for it
            db.add(Appointment(patient_id=p.id, doctor_id=doctor.id, day=when.date(), time_from=time(rng.randint(9, 16)), status="done"))
            if rng.random() < .6:
                db.add(Review(doctor_id=doctor.id, patient_id=p.id, rate=Decimal(str(rng.choice([3, 4, 4, 4.5, 5, 5]))),
                              message=rng.choice(["Very attentive and explained everything.", "Short waiting time.", "Good doctor, clinic is hard to find.", "Highly recommended.", ""]), sent_at=when + timedelta(days=1)))

    # ---- upcoming appointments (respecting each doctor's schedule, one per hour)
    taken: set[tuple] = set()
    for p in patients:
        for _ in range(rng.choice([0, 1, 1, 2])):
            doctor = rng.choice(doctors)
            if not doctor.schedule:
                continue
            for _try in range(10):
                offset = rng.randint(1, 14)
                day = today + timedelta(days=offset)
                window = next((s for s in doctor.schedule if s.day_name == day.strftime("%A")), None)
                if window is None:
                    continue
                hour = rng.randint(window.time_from.hour, max(window.time_from.hour, window.time_to.hour - 1))
                key = (doctor.id, day, hour)
                if key in taken:
                    continue
                taken.add(key)
                db.add(Appointment(patient_id=p.id, doctor_id=doctor.id, day=day, time_from=time(hour), status="booked"))
                break
    await db.commit()

    # ---- conversations (a patient-doctor chat needs a booking first, so make sure one exists)
    pharmacies = (await db.scalars(select(Pharmacy))).all()
    hospitals = (await db.scalars(select(Hospital))).all()
    for kind, a, b, subject, lines in CHATS:
        if kind == "patient":
            me, other = patients[a], doctors[b].user
            booked = await db.scalar(select(Appointment.id).where(Appointment.patient_id == me.id, Appointment.doctor_id == doctors[b].id).limit(1))
            if not booked:
                window = doctors[b].schedule[0]
                day = today + timedelta(days=1)
                while day.strftime("%A") != window.day_name:
                    day += timedelta(days=1)
                db.add(Appointment(patient_id=me.id, doctor_id=doctors[b].id, day=day, time_from=window.time_from, status="booked"))
                await db.commit()
        elif kind == "pharmacy":
            me, other = patients[a], pharmacies[b].owner
        elif kind == "colleague":
            me, other = doctors[a].user, doctors[b].user
        elif kind == "support":
            me, other = support, patients[a]  # support can write to anyone
        else:
            me, other = hospitals[a].owner, doctors[b].user
        try:
            conv = await start_or_get(db, me, other, subject)
        except Exception:  # noqa: BLE001 - a rule may block it; demo data is best effort
            continue
        if await db.scalar(select(func.count()).select_from(ChatMessage).where(ChatMessage.conversation_id == conv.id)):
            continue
        t = now - timedelta(days=2)
        for who, text in lines:
            sender = (other if who == "p" else me) if kind == "support" else (me if who in ("p", "h", "a") else other)
            t += timedelta(minutes=rng.randint(2, 40))
            db.add(ChatMessage(conversation_id=conv.id, sender_id=sender.id, text=text, sent_at=t, read_at=t if sender.id != me.id else None))
        conv.last_message_at = t
    await db.commit()

    # ---- notifications, so the bell is not empty
    sara, main_doctor = patients[0], doctors[0]
    for type_, text in [
        (NotificationType.APPOINTMENT_REMINDER, "Reminder: you have a visit with Dr. Ahmed Hassan soon."),
        (NotificationType.NEW_PRESCRIPTION, "Dr. Ahmed Hassan added Warfarin to your prescriptions."),
        (NotificationType.NEW_MESSAGE, "New message from El Nour Pharmacy."),
    ]:
        db.add(Notification(user_id=sara.id, type=type_, message=text, created_at=now - timedelta(hours=rng.randint(1, 48))))
    db.add(Notification(user_id=main_doctor.user_id, type=NotificationType.DOCTOR_SELECTED_DATE, message="Sara Ali booked a visit with you.", created_at=now - timedelta(hours=5)))
    db.add(Notification(user_id=main_doctor.user_id, type=NotificationType.NEW_MESSAGE, message="New message from Dr. Heba Mahmoud.", created_at=now - timedelta(hours=2)))
    await db.commit()

    print(f"Demo data ready: {products} products, {len(doctors)} doctors, {len(HOSPITALS)} hospitals, {len(PHARMACIES)} pharmacies, {len(patients)} patients, "
          f"1 support account, {len(PENDING_DOCTORS) + len(PENDING_HOSPITALS) + len(PENDING_PHARMACIES)} applications for the admin, "
          "appointments, records, reviews, notifications and conversations")
    print("Demo logins (password = Role@12345): patient@, doctor@, pharmacy@, hospital@, support@ (Support@12345), admin@healthhub.local")
