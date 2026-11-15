"""More demo data, added on top of app/demo.py so the apps feel like a real, busy service.

    python -m app.seed --demo       adds it (together with the base demo, if that is missing)

It only adds. Nothing that exists is changed or deleted, and running it twice adds nothing the second
time, so an existing database (with the base demo or your own data) can take it at any time.

Adds: 40 doctors so every one of the 27 governorates has at least one, 9 hospitals, 21 pharmacies
with stock, 115 patients (some of them children), a year of visits with follow-ups and vital signs,
prescriptions, cancelled visits, upcoming bookings, reviews in English and Arabic, conversations in
English and Egyptian Arabic, notifications, and a few more applications for the admin.
Passwords are the same as the base demo: <Role>@12345.
"""

import random
from datetime import date, datetime, time, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.demo import _area, _nid, _specialty, _user
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
    User,
)
from app.models.chat import ChatMessage
from app.services.chat import start_or_get

rng = random.Random(2026)  # fixed seed: the same data every time

# The first new doctor. If this account exists, this module already ran.
MARKER_EMAIL = "tarek.abdelrahman@healthhub.local"

MALE = ["Tarek", "Mohamed", "Mahmoud", "Mostafa", "Omar", "Youssef", "Karim", "Hesham", "Amr", "Sameh", "Wael", "Ayman",
        "Hany", "Ashraf", "Ehab", "Sherif", "Ramy", "Hazem", "Tamer", "Ibrahim", "Khaled", "Medhat", "Nabil", "Osama",
        "Fady", "Mina", "Bishoy", "Gamal", "Adel", "Hassan", "Ali", "Saad", "Yasser", "Magdy", "Essam", "Reda", "Atef",
        "Anas", "Zeyad", "Marwan"]
FEMALE = ["Mona", "Heba", "Rania", "Dina", "Nermeen", "Shaimaa", "Yasmine", "Nada", "Aya", "Mai", "Marwa", "Doaa", "Eman",
          "Hala", "Ghada", "Amira", "Sally", "Mariam", "Nesma", "Basma", "Reham", "Asmaa", "Fatma", "Esraa", "Samar", "Noha",
          "Lamiaa", "Christine", "Marina", "Engy", "Rasha", "Inas", "Abeer", "Soha", "Walaa", "Hagar", "Rana", "Nourhan",
          "Salma", "Farah"]
LAST = ["Abdelrahman", "El Sayed", "Hassan", "Mahmoud", "Ibrahim", "Mostafa", "Abdallah", "Fathy", "Shawky", "Ragab",
        "Hamdy", "Hegazy", "Zaki", "Soliman", "Mansour", "Badawy", "Nasr", "Fouad", "Lotfy", "Salem", "Gaber", "Kamel",
        "Aziz", "Naguib", "Wahba", "Girgis", "Shenouda", "Morsy", "Rashwan", "El Masry", "Abdelaziz", "Sobhy", "Tantawy",
        "Okasha", "El Gendy", "Shalaby", "Mekky", "Eid", "Ghoneim", "Farag"]

# Main towns of each governorate, spelled as in the address data.
GOV_AREAS = {
    "Cairo": ["Maadi", "Nasr City", "New Heliopolis", "Zamalek", "New Cairo", "Shubra", "Mokattam", "Abaseya", "Ain Shams", "Helwan", "Garden City", "Katameya"],
    "Giza": ["Dokki", "Mohandessin", "Agouza", "Haram", "Faisal", "Cheikh Zayed", "Sixth of October", "Imbaba"],
    "Alexandria": ["Smouha", "Sidi Gaber", "Sidi Bishr", "Cleopatra", "Fleming", "Elshatby", "Agamy", "El Montaza", "Glim"],
    "Aswan": ["Aswan", "Kom Ombo", "Edfu"], "Assiut": ["Assiut", "Manfalut", "Abnoub"], "Beheira": ["Damanhour", "Kafr El Dawar", "Rashid"],
    "Beni Suef": ["Bani Sweif", "Al Wasta", "Beni Suef El Gedida"], "Dakahlia": ["Mansoura", "Talkha", "Mitt Ghamr"],
    "Damietta": ["Damietta", "New Damietta", "Ras El Bar"], "Fayoum": ["Fayoum", "Tamiya", "Fayoum El Gedida"],
    "Gharbiya": ["Tanta", "Al Mahalla Al Kobra", "Kafr El Zayat"], "Ismailia": ["Ismailia", "Fayed", "Qantara Gharb"],
    "Kafr Al sheikh": ["Kafr El Sheikh", "Desouq", "Baltim"], "Luxor": ["Luxor", "Esna", "Armant"], "Matrouh": ["Marsa Matrouh", "Alamein", "Siwa"],
    "Menofia": ["Shbeen El Koom", "Menouf", "Sadat City"], "Minya": ["Minya", "Samalut", "Bani Mazar"], "New Valley": ["El Kharga", "Dakhla"],
    "North Sinai": ["Arish", "Bir al-Abed"], "Port Said": ["PorSaid", "Port Fouad"], "Qaliubiya": ["Banha", "Shubra Al Khaimah", "Qalyub", "Obour"],
    "Qena": ["Qena", "Nag Hammadi", "New Qena"], "Red Sea": ["Hurghada", "Safaga", "El Qusiar"], "Sharkia": ["Zagazig", "Al Ashr Men Ramadan", "Belbeis"],
    "Sohag": ["Sohag", "Akhmeem", "Gerga"], "South Sinai": ["Sharm El-Shaikh", "Dahab", "Al Toor"], "Suez": ["Suez", "Ain Sokhna"],
}

COLLEGE = {
    "Cairo": "Cairo University", "Giza": "Cairo University", "Alexandria": "Alexandria University", "Beheira": "Alexandria University",
    "Matrouh": "Alexandria University", "Dakahlia": "Mansoura University", "Damietta": "Mansoura University", "Gharbiya": "Tanta University",
    "Kafr Al sheikh": "Kafrelsheikh University", "Menofia": "Menoufia University", "Sharkia": "Zagazig University", "Qaliubiya": "Benha University",
    "Assiut": "Assiut University", "New Valley": "Assiut University", "Sohag": "Sohag University", "Qena": "South Valley University",
    "Luxor": "South Valley University", "Red Sea": "South Valley University", "Aswan": "Aswan University", "Minya": "Minia University",
    "Beni Suef": "Beni-Suef University", "Fayoum": "Fayoum University", "Ismailia": "Suez Canal University", "Port Said": "Suez Canal University",
    "Suez": "Suez Canal University", "North Sinai": "Suez Canal University", "South Sinai": "Suez Canal University",
}
BIG_CITY_COLLEGES = ["Cairo University", "Ain Shams University", "Al-Azhar University"]

# specialty -> (base visit price in EGP, two career summaries)
SPECIALTIES = {
    "Cardiology": (400, ["Cardiologist. Heart failure, chest pain and blood pressure clinic.", "Interventional cardiology, echo and stress tests."]),
    "Paediatrics": (300, ["Paediatrician. Newborn care, vaccines and growth follow-up.", "Children's chest allergy and asthma clinic."]),
    "Obstetrics and gynaecology": (350, ["Gynaecologist. Pregnancy follow-up and ultrasound.", "Fertility, PCOS and women's health."]),
    "Internal medicine": (300, ["Internist. Diabetes, blood pressure and general check-ups.", "Internal medicine and liver clinic."]),
    "Dermatology": (300, ["Dermatologist. Acne, eczema and hair loss.", "Skin, hair and nails, with laser sessions."]),
    "Orthopaedics": (350, ["Orthopaedic surgeon. Knee, back and sports injuries.", "Joints, fractures and arthroscopy."]),
    "General practice": (200, ["Family doctor for all ages. First stop for any complaint.", "General practitioner. Check-ups, colds and minor injuries."]),
    "Dental, oral and maxillo-facial surgery": (250, ["Dentist. Fillings, root canals and implants.", "Children's dentistry and orthodontics."]),
    "Ophthalmology": (300, ["Eye doctor. Glasses, glaucoma and cataract follow-up.", "Ophthalmologist and LASIK consultant."]),
    "Otorhinolaryngology": (300, ["ENT surgeon. Sinus, tonsils and hearing.", "Ear, nose and throat, adults and children."]),
    "Neurology": (400, ["Neurologist. Headache, epilepsy and nerve pain.", "Stroke follow-up and nerve conduction studies."]),
    "Psychiatry": (450, ["Psychiatrist. Anxiety, depression and sleep problems.", "Adult psychiatry and family counselling."]),
    "Endocrinology": (400, ["Endocrinologist. Diabetes, thyroid and hormones.", "Diabetes and obesity clinic."]),
    "Gastroenterology": (400, ["Gastroenterologist. Stomach, colon and liver.", "Endoscopy and H. pylori clinic."]),
    "Urology": (350, ["Urologist. Kidney stones and prostate.", "Urology and men's health."]),
    "Nephrology": (400, ["Nephrologist. Kidney disease and dialysis follow-up.", "Kidney and blood pressure clinic."]),
    "Respiratory medicine": (300, ["Chest physician. Asthma, COPD and allergy.", "Chest and sleep apnoea clinic."]),
    "Rheumatology": (350, ["Rheumatologist. Arthritis and back pain.", "Rheumatoid arthritis, lupus and gout clinic."]),
    "Physical medicine and rehabilitation": (300, ["Physiotherapy after injuries and surgery.", "Back pain and sports rehabilitation."]),
    "Infectious diseases": (300, ["Infectious diseases and fevers.", "Hepatitis and travel medicine."]),
    "Geriatrics": (350, ["Care for older adults, memory and balance.", "Elderly care and home visit plans."]),
    "Vascular surgery": (450, ["Vascular surgeon. Varicose veins and diabetic foot.", "Arteries, veins and wound care."]),
    "Plastic surgery": (500, ["Plastic surgeon. Burns and scars.", "Reconstructive and cosmetic surgery."]),
}

# 40 doctors: the big cities get several, every other governorate gets one.
DOCTOR_GOVS = ["Cairo"] * 7 + ["Giza"] * 4 + ["Alexandria"] * 5 + [
    "Aswan", "Assiut", "Beheira", "Beni Suef", "Dakahlia", "Damietta", "Fayoum", "Gharbiya", "Ismailia", "Kafr Al sheikh",
    "Luxor", "Matrouh", "Menofia", "Minya", "New Valley", "North Sinai", "Port Said", "Qaliubiya", "Qena", "Red Sea",
    "Sharkia", "Sohag", "South Sinai", "Suez"]
# outside the big cities, the specialties people need most
COMMON = ["General practice", "Internal medicine", "Paediatrics", "Obstetrics and gynaecology", "Cardiology", "Dermatology",
          "Orthopaedics", "Dental, oral and maxillo-facial surgery", "Ophthalmology", "Otorhinolaryngology", "Endocrinology", "Urology"]

HOSPITALS = [
    # name, governorate, area, address, phone, description, departments by specialty
    ("Heliopolis Family Hospital", "Cairo", "New Heliopolis", "12 El Hegaz St.", "0226401122", "Family hospital with maternity, children's and emergency wings.",
     ["Obstetrics and gynaecology", "Paediatrics", "Internal medicine", "Cardiology"]),
    ("Pyramids Medical Center", "Giza", "Haram", "88 Al Haram St.", "0235831144", "Outpatient clinics, day surgery and physiotherapy.",
     ["Orthopaedics", "Physical medicine and rehabilitation", "Dermatology", "General practice"]),
    ("Mediterranean Care Hospital", "Alexandria", "Sidi Gaber", "5 Abu Qir St.", "0354201133", "General hospital with ICU, cath lab and dialysis.",
     ["Cardiology", "Nephrology", "Neurology", "Internal medicine"]),
    ("Delta Children's Hospital", "Gharbiya", "Tanta", "40 El Galaa St.", "0403301155", "Children's hospital with a neonatal unit.", ["Paediatrics", "Otorhinolaryngology", "General practice"]),
    ("Canal Care Hospital", "Ismailia", "Ismailia", "17 Sultan Hussein St.", "0643201166", "Serves Ismailia, Port Said and Suez.", ["Obstetrics and gynaecology", "Internal medicine", "Orthopaedics"]),
    ("South Valley Medical Center", "Qena", "Qena", "3 El Gomhoria St.", "0965301177", "Clinics, lab and radiology for Upper Egypt.", ["Internal medicine", "Paediatrics", "General practice"]),
    ("Aswan Heart Center", "Aswan", "Aswan", "Corniche El Nil", "0972301188", "Heart and chest care in the far south.", ["Cardiology", "Respiratory medicine", "General practice"]),
    ("Sinai Health Clinic", "South Sinai", "Sharm El-Shaikh", "Peace Road", "0693601199", "Clinics and emergency care for residents and visitors.", ["General practice", "Dermatology", "Orthopaedics"]),
    ("Fayoum Oasis Hospital", "Fayoum", "Fayoum", "9 El Batal Ahmed Abdelaziz St.", "0842301100", "General hospital with day surgery.", ["Internal medicine", "Obstetrics and gynaecology", "Orthopaedics"]),
]

PHARMACY_NAMES = ["Al Hayah", "Al Shams", "Al Amal", "Al Salam", "Al Rahma", "Al Zahraa", "Al Mostakbal", "Al Hekma", "Al Dawaa",
                  "Al Safa", "Al Wafaa", "Al Andalus", "Al Forsan", "Al Nada", "Al Basma", "Al Yasmeen", "Al Fayrouz", "Al Morooj",
                  "Al Tahrir", "Al Gomhoria", "Al Bashayer"]
PHARMACY_GOVS = ["Cairo", "Cairo", "Cairo", "Cairo", "Giza", "Giza", "Alexandria", "Alexandria", "Qaliubiya", "Sharkia", "Menofia",
                 "Beheira", "Minya", "Sohag", "Luxor", "Aswan", "Port Said", "Damietta", "Fayoum", "Beni Suef", "Red Sea"]

# where the 115 new patients live (roughly by population)
PATIENT_GOVS = (["Cairo"] * 28 + ["Giza"] * 16 + ["Alexandria"] * 13 + ["Qaliubiya"] * 6 + ["Sharkia"] * 6 + ["Dakahlia"] * 6
                + ["Gharbiya"] * 5 + ["Menofia"] * 4 + ["Beheira"] * 4 + ["Minya"] * 4 + ["Assiut"] * 4 + ["Sohag"] * 4
                + ["Aswan", "Beni Suef", "Damietta", "Fayoum", "Ismailia", "Kafr Al sheikh", "Luxor", "Matrouh", "New Valley",
                   "North Sinai", "Port Said", "Qena", "Red Sea", "South Sinai", "Suez"])

# condition -> (specialty, medicines, chronic). Medicines are active ingredients; most have Egyptian brands in stock.
ADULT_CONDITIONS = {
    "Hypertension": ("Cardiology", ["bisoprolol", "amlodipine"], True),
    "Type 2 diabetes": ("Endocrinology", ["metformin", "gliclazide"], True),
    "Hyperlipidaemia": ("Cardiology", ["rosuvastatin"], True),
    "Heart failure": ("Cardiology", ["sacubitril", "bisoprolol", "spironolactone", "furosemide"], True),
    "Hypothyroidism": ("Endocrinology", ["levothyroxine"], True),
    "H. pylori gastritis": ("Gastroenterology", ["omeprazole", "clarithromycin", "amoxicillin"], False),
    "GERD": ("Gastroenterology", ["pantoprazole", "domperidone"], True),
    "Irritable bowel syndrome": ("Gastroenterology", ["loperamide"], False),
    "Knee osteoarthritis": ("Orthopaedics", ["celecoxib"], True),
    "Lower back pain": ("Physical medicine and rehabilitation", ["diclofenac", "pregabalin"], False),
    "Rheumatoid arthritis": ("Rheumatology", ["methotrexate", "folic acid", "hydroxychloroquine"], True),
    "Gout": ("Rheumatology", ["febuxostat", "colchicine"], True),
    "Psoriasis": ("Dermatology", ["betamethasone"], True),
    "Fungal skin infection": ("Dermatology", ["terbinafine", "clotrimazole"], False),
    "Acne vulgaris": ("Dermatology", ["doxycycline"], False),
    "Chronic sinusitis": ("Otorhinolaryngology", ["mometasone", "cetirizine"], True),
    "Acute bronchitis": ("Respiratory medicine", ["azithromycin", "ambroxol"], False),
    "COPD": ("Respiratory medicine", ["budesonide", "salbutamol"], True),
    "Depression": ("Psychiatry", ["sertraline"], True),
    "Generalised anxiety": ("Psychiatry", ["escitalopram"], True),
    "Migraine": ("Neurology", ["ibuprofen", "propranolol"], True),
    "Epilepsy": ("Neurology", ["levetiracetam"], True),
    "Diabetic neuropathy": ("Neurology", ["pregabalin", "cyanocobalamin"], True),
    "Kidney stones": ("Urology", ["tamsulosin", "diclofenac"], False),
    "Benign prostatic hyperplasia": ("Urology", ["tamsulosin", "finasteride"], True),
    "Chronic kidney disease": ("Nephrology", ["furosemide", "calcium carbonate"], True),
    "Vitamin D deficiency": ("Internal medicine", ["cholecalciferol", "calcium carbonate"], False),
    "Vitamin B12 deficiency": ("Internal medicine", ["cyanocobalamin", "folic acid"], False),
    "Urinary tract infection": ("Internal medicine", ["ciprofloxacin"], False),
    "Influenza": ("General practice", ["oseltamivir", "acetaminophen"], False),
    "Gastroenteritis": ("General practice", ["metronidazole", "loperamide"], False),
    "Pregnancy follow-up": ("Obstetrics and gynaecology", ["folic acid", "calcium carbonate"], False),
    "Polycystic ovary syndrome": ("Obstetrics and gynaecology", ["metformin"], True),
    "Glaucoma": ("Ophthalmology", ["timolol", "latanoprost"], True),
    "Allergic conjunctivitis": ("Ophthalmology", ["ketotifen", "loratadine"], False),
    "Dental abscess": ("Dental, oral and maxillo-facial surgery", ["amoxicillin", "metronidazole", "ibuprofen"], False),
    "Varicose veins": ("Vascular surgery", ["acetylsalicylic acid"], True),
}
CHILD_CONDITIONS = {
    "Childhood asthma": ("Paediatrics", ["salbutamol", "montelukast"], True),
    "Acute tonsillitis": ("Paediatrics", ["amoxicillin", "ibuprofen"], False),
    "Otitis media": ("Otorhinolaryngology", ["amoxicillin", "acetaminophen"], False),
    "Allergic rhinitis": ("Paediatrics", ["cetirizine"], False),
    "Gastroenteritis": ("Paediatrics", ["ondansetron"], False),
    "Atopic eczema": ("Dermatology", ["betamethasone"], False),
    "Vitamin D deficiency": ("Paediatrics", ["cholecalciferol"], False),
    "Dental caries": ("Dental, oral and maxillo-facial surgery", ["acetaminophen"], False),
}
REPEATS = {"daily": 1, "every 12 hours": 2, "every 8 hours": 3, "once a week": 1, "when needed": 1}
PRESCRIPTION_NOTES = ["after food", "before breakfast", "at night", "with plenty of water", "for 5 days then stop", None]


def _first_notes(cond: str) -> str:
    """Notes a doctor would write on the first visit, with realistic numbers."""
    bp = f"BP {rng.randint(118, 168)}/{rng.randint(74, 102)}"
    if cond in ("Hypertension", "Heart failure"):
        return f"{bp}, pulse {rng.randint(64, 98)}. Low-salt diet, home BP diary."
    if cond in ("Type 2 diabetes", "Diabetic neuropathy", "Polycystic ovary syndrome"):
        return f"Fasting sugar {rng.randint(118, 210)} mg/dL, HbA1c {rng.uniform(6.6, 9.8):.1f}%. Diet and walking 30 min a day."
    if cond == "Hyperlipidaemia":
        return f"LDL {rng.randint(140, 210)} mg/dL, triglycerides {rng.randint(150, 320)}. Recheck lipids in 3 months."
    if cond == "Hypothyroidism":
        return f"TSH {rng.uniform(5.5, 14):.1f} mIU/L. Take the tablet on an empty stomach."
    if cond == "Chronic kidney disease":
        return f"Creatinine {rng.uniform(1.6, 3.4):.1f} mg/dL, eGFR {rng.randint(28, 55)}. Limit salt and protein."
    if cond in ("Influenza", "Acute bronchitis", "Acute tonsillitis", "Otitis media"):
        return f"Temperature {rng.uniform(37.8, 39.4):.1f} °C. Rest, fluids, come back if no better in 3 days."
    if cond == "Pregnancy follow-up":
        return f"Week {rng.randint(8, 34)}. {bp}. Baby's heartbeat normal on ultrasound."
    if cond in ("Knee osteoarthritis", "Lower back pain", "Rheumatoid arthritis", "Gout"):
        return rng.choice(["X-ray requested.", "Physiotherapy twice a week.", "Weight loss advised.", f"Uric acid {rng.uniform(7.2, 10.5):.1f} mg/dL."])
    if cond in ("Depression", "Generalised anxiety"):
        return f"PHQ-9 score {rng.randint(10, 19)}. Weekly sessions, sleep routine."
    return rng.choice(["Lifestyle advice given.", "Labs requested.", "Follow up in 4 weeks.", "Symptoms explained, return if worse."])


def _follow_up_notes(cond: str) -> str:
    if cond in ("Hypertension", "Heart failure"):
        return f"BP {rng.randint(118, 145)}/{rng.randint(72, 92)}. Better. Same treatment."
    if cond in ("Type 2 diabetes", "Diabetic neuropathy", "Polycystic ovary syndrome"):
        return f"HbA1c down to {rng.uniform(6.2, 7.9):.1f}%. Keep the same dose."
    if cond == "Hyperlipidaemia":
        return f"LDL now {rng.randint(80, 130)} mg/dL. Continue."
    if cond == "Hypothyroidism":
        return f"TSH {rng.uniform(1.2, 4.2):.1f} mIU/L, normal. Same dose."
    return rng.choice(["Stable. Continue the same treatment.", "Improving. Review in 3 months.", "Better. Medicines adjusted.", "No complaints today."])


REVIEWS_EN = ["Very attentive and explained everything clearly.", "Short waiting time and a clean clinic.",
              "Took the time to answer all my questions.", "Good doctor, but the clinic was crowded.",
              "Highly recommended for the whole family.", "Professional and kind.", "Replied to my messages in the app the same day.",
              "Found the problem after two other doctors missed it.", ""]
REVIEWS_AR = ["دكتور محترم جدًا وبيشرح كل حاجة بالتفصيل", "الانتظار كان قليل والعيادة نضيفة", "شخّص الحالة صح من أول زيارة",
              "كويس بس العيادة زحمة شوية", "أنصح بيه جدًا", "متعاون جدًا وبيرد على الرسايل", "ربنا يبارك فيه، تعبت كتير قبل ما أوصله"]

# conversations: p = patient, d = doctor, ph = pharmacy, a / b = two doctors, h = hospital, s = support
PATIENT_DOCTOR_CHATS = [
    ("Question about the dose", [("p", "Hello doctor, I forgot my evening dose yesterday. Should I take two today?"),
                                 ("d", "No, never double the dose. Just continue as usual today."), ("p", "Okay, thank you.")]),
    ("Side effect", [("p", "Doctor, the new tablets give me a mild headache."),
                     ("d", "That usually fades in the first week. If it doesn't, message me and we will adjust.")]),
    ("Travelling", [("p", "Is it fine to travel next week?"),
                    ("d", "Yes. Take enough medicine for the whole trip and keep it in your hand luggage.")]),
    ("Lab results", [("d", "Hi {patient}, your lab results are in. Everything looks stable."), ("p", "Great news, thank you doctor!")]),
    ("Second patient", [("p", "Can I bring my daughter to the same appointment?"),
                        ("d", "Of course. Book a separate visit for her in the app so I have time for both of you.")]),
    ("سؤال عن العلاج", [("p", "مساء الخير يا دكتور، أقدر آخد الدوا بعد الأكل؟"),
                        ("d", "أيوه، بعد الأكل أحسن للمعدة. ولو حسيت بأي تعب كلمني."), ("p", "شكرًا يا دكتور")]),
    ("متابعة", [("p", "دكتور، الحرارة نزلت الحمد لله بس لسه فيه كحة خفيفة"),
                ("d", "ده طبيعي، الكحة بتاخد أسبوع كمان. كمّل العلاج واشرب سوايل كتير.")]),
    ("تغيير الميعاد", [("p", "ممكن أأجل الميعاد لبعد بكرة؟"),
                       ("d", "تمام، غيّره من صفحة المواعيد في التطبيق وهيوصلني إشعار.")]),
    ("التحاليل", [("p", "عملت التحاليل اللي حضرتك طلبتها، أبعتها إزاي؟"),
                  ("d", "ارفعها في الملف الطبي من التطبيق وأنا هشوفها قبل الزيارة."), ("p", "تمام، رفعتها دلوقتي")]),
    ("النتيجة", [("d", "أهلًا {patient}، النتيجة كويسة. كمّل على نفس الجرعة ونشوفك بعد ٣ شهور."), ("p", "الحمد لله، شكرًا يا دكتور")]),
]
PATIENT_PHARMACY_CHATS = [
    ("Stock question", [("p", "Hi, do you have {brand} in stock?"), ("ph", "Yes, we have it for {price} EGP."),
                        ("p", "Can you keep one box for me? I'll pass by tonight."), ("ph", "Done, it's under your name.")]),
    ("Delivery", [("p", "Do you deliver to {area}?"), ("ph", "Yes, delivery is 15 EGP and takes about 45 minutes.")]),
    ("سؤال عن دوا", [("p", "السلام عليكم، عندكم {brand}؟"), ("ph", "وعليكم السلام، أيوه موجود بـ {price} جنيه."),
                     ("p", "تمام، هعدي عليكم بالليل")]),
    ("بديل", [("p", "عندكم بديل لـ {brand}؟ مش لاقيه في أي حتة"),
              ("ph", "فيه نفس المادة الفعالة من شركة تانية، بس لازم الدكتور يوافق الأول.")]),
    ("الروشتة", [("p", "الروشتة اللي في التطبيق ينفع أصرفها عندكم؟"), ("ph", "أيوه، ابعتلنا كود الروشتة من التطبيق وهنجهزها.")]),
]
COLLEAGUE_CHATS = [
    ("Referral", [("a", "Dr. {b}, can you see a patient of mine this week? I'd like your opinion."), ("b", "Sure, send them to my clinic on Sunday at 11.")]),
    ("استشارة", [("a", "دكتور {b}، عندي حالة محتاجة رأيك، ممكن أبعتلك الأشعة؟"), ("b", "أكيد، ابعتها وهرد عليك النهارده")]),
]
HOSPITAL_DOCTOR_CHATS = [
    ("On-call days", [("h", "Dr. {b}, please confirm your on-call days for next month."), ("d", "Sunday and Wednesday work for me.")]),
    ("مواعيد العيادة", [("h", "دكتور {b}، العيادة الخارجية هتبدأ ٩ الصبح بدل ١٠ من الأسبوع الجاي."), ("d", "تمام، شكرًا للتنبيه")]),
]
SUPPORT_CHATS = [
    ("Prescription code", [("p", "I can't find my prescription code."), ("s", "Open Records, then tap Share prescriptions. The code is at the top.")]),
    ("صورة البروفايل", [("p", "مش عارف أغيّر صورة البروفايل"), ("s", "من صفحة الملف الشخصي اضغط على الصورة واختار صورة جديدة."),
                        ("p", "تمام اشتغلت، شكرًا")]),
    ("Booking for a child", [("p", "How do I book for my son? He has no account."),
                             ("s", "Book from your own account and write his name in the note. One account can book for the family.")]),
]

PENDING_DOCTORS = [("Ramy Wahba", "Psychiatry", "Alexandria"), ("Engy Naguib", "Ophthalmology", "Giza"), ("Atef Rashwan", "Urology", "Sohag")]
PENDING_PHARMACIES = [("Al Karma Pharmacy, Zagazig", "Sharkia", "Zagazig")]
PENDING_HOSPITALS = [("Upper Nile Day Clinic", "Luxor", "Luxor")]


async def _place(db: AsyncSession, gov: str, area: str | None = None) -> Area:
    """An area by exact name in that governorate (or one of its main towns)."""
    name = area or rng.choice(GOV_AREAS[gov])
    row = await db.scalar(select(Area).join(Governorate).where(Governorate.key == gov, Area.key == name))
    return row or await _area(db, gov, name)


def _email(first: str, last: str, used: set[str]) -> str:
    base = f"{first}.{last}".lower().replace(" ", "")
    email, n = f"{base}@healthhub.local", 2
    while email in used:
        email, n = f"{base}{n}@healthhub.local", n + 1
    used.add(email)
    return email


def _name(male: bool, used: set[str]) -> tuple[str, str]:
    for _ in range(200):
        first, last = rng.choice(MALE if male else FEMALE), rng.choice(LAST)
        if f"{first} {last}" not in used:
            used.add(f"{first} {last}")
            return first, last
    raise RuntimeError("ran out of demo names")


async def _free_hour(db: AsyncSession, doctor: Doctor, day: date, taken: set, from_hour: int = 0) -> int | None:
    window = next((s for s in doctor.schedule if s.day_name == day.strftime("%A")), None)
    if window is None:
        return None
    hours = [h for h in range(max(window.time_from.hour, from_hour), window.time_to.hour) if (doctor.id, day, h) not in taken]
    if not hours:
        return None
    hour = rng.choice(hours)
    taken.add((doctor.id, day, hour))
    return hour


async def _chat(db: AsyncSession, me: User, other: User, subject: str, lines: list[tuple[str, str]], roles: dict[str, User], when: datetime, fill: dict) -> bool:
    try:
        conv = await start_or_get(db, me, other, subject)
    except Exception:  # noqa: BLE001 - a chat rule may block a pair; demo data is best effort
        await db.rollback()
        return False
    if await db.scalar(select(func.count()).select_from(ChatMessage).where(ChatMessage.conversation_id == conv.id)):
        return False
    t = when
    for who, text in lines:
        sender = roles[who]
        t += timedelta(minutes=rng.randint(3, 90))
        # the last message stays unread for the person it was sent to, so the inbox shows a badge
        db.add(ChatMessage(conversation_id=conv.id, sender_id=sender.id, text=text.format(**fill), sent_at=t, read_at=t + timedelta(minutes=5)))
    conv.last_message_at = t
    last = await db.scalar(select(ChatMessage).where(ChatMessage.conversation_id == conv.id).order_by(ChatMessage.sent_at.desc()).limit(1))
    if last is not None and rng.random() < .5:
        last.read_at = None
    await db.commit()
    return True


async def seed_demo_more(db: AsyncSession) -> None:
    if await db.scalar(select(User.id).where(User.email == MARKER_EMAIL)):
        print("Extra demo data already present, skipping")
        return
    if not await db.scalar(select(User.id).where(User.email == "doctor@healthhub.local")):
        print("Base demo data missing, so the extra demo data is skipped")
        return

    now = datetime.now(timezone.utc)
    today = date.today()
    used_emails = set((await db.scalars(select(User.email))).all())
    used_names = set((await db.scalars(select(User.name))).all())

    # ---- doctors
    specs_cycle = list(SPECIALTIES)
    rng.shuffle(specs_cycle)
    new_doctors: list[Doctor] = []
    for i, gov in enumerate(DOCTOR_GOVS):
        male = rng.random() < .6
        if i == 0:
            first, last, male = "Tarek", "Abdelrahman", True  # the marker account
            used_names.add("Tarek Abdelrahman")
        else:
            first, last = _name(male, used_names)
        spec = specs_cycle[i % len(specs_cycle)] if gov in ("Cairo", "Giza", "Alexandria") else COMMON[i % len(COMMON)]
        base_price, summaries = SPECIALTIES[spec]
        price = base_price + (100 if gov in ("Cairo", "Giza", "Alexandria") else 0) + rng.choice([-50, 0, 0, 50])
        area = await _place(db, gov)
        birth = date(1968 + rng.randint(0, 24), rng.randint(1, 12), rng.randint(1, 28))
        email = MARKER_EMAIL if i == 0 else _email(first, last, used_emails)
        user = await _user(db, email=email, password="Doctor@12345", name=f"{first} {last}", roles=[Role.PATIENT, Role.DOCTOR], area=area,
                           phone=f"0101{5000000 + i:07d}", national_id=_nid(500 + i, birth), male=male, birth=birth)
        college = rng.choice(BIG_CITY_COLLEGES) if gov in ("Cairo", "Giza") else COLLEGE[gov]
        doctor = Doctor(
            user_id=user.id, specialty_id=(await _specialty(db, spec)).id, area_id=area.id, college_name=college,
            summary_career=rng.choice(summaries), address_description=f"{rng.randint(2, 120)} {area.key} St., floor {rng.randint(1, 6)}",
            accepted=True, price_session=Decimal(max(150, price)), date_of_join=now - timedelta(days=rng.randint(20, 700)),
            graduation_year=date(birth.year + 24, 6, 1),
        )
        db.add(doctor)
        await db.flush()
        days = rng.sample(["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"], k=rng.choice([3, 4, 4, 5]))
        start = rng.choice([10, 12, 14, 16, 17])
        for d in days:
            db.add(DoctorSchedule(doctor_id=doctor.id, day_name=d, time_from=time(start), time_to=time(min(start + rng.choice([4, 5, 6]), 22))))
        new_doctors.append(doctor)
    await db.commit()

    all_doctors = (await db.scalars(select(Doctor).where(Doctor.accepted.is_(True)).execution_options(populate_existing=True))).all()
    gov_of_area = {a.id: g for a, g in (await db.execute(select(Area, Governorate.key).join(Governorate))).all()}
    doctors_by_spec: dict[str, list[Doctor]] = {}
    for d in all_doctors:
        doctors_by_spec.setdefault(d.specialty.name, []).append(d)

    # ---- hospitals, staffed with doctors from the same governorate
    new_hospitals: list[Hospital] = []
    for i, (name, gov, area_name, address, phone, desc, departments) in enumerate(HOSPITALS):
        area = await _place(db, gov, area_name)
        slug = ".".join(w for w in name.lower().replace("'", "").split() if w not in ("hospital", "center", "medical", "clinic", "health"))
        owner = await _user(db, email=f"{slug}@healthhub.local", password="Hospital@12345",
                            name=f"{name} Manager", roles=[Role.PATIENT, Role.HOSPITAL], area=area, phone=f"0151{6000000 + i:07d}",
                            national_id=_nid(600 + i, date(1972, 6, 6 + i)), male=i % 2 == 0, birth=date(1972, 6, 6 + i))
        hospital = Hospital(owner_id=owner.id, name=name, area_id=area.id, address_description=address, phone=phone, description=desc, accepted=True)
        db.add(hospital)
        await db.flush()
        local = [d for d in all_doctors if gov_of_area.get(d.area_id) == gov]
        added = set()
        for dept in departments:
            match = next((d for d in local if d.specialty.name == dept and d.id not in added), None)
            if match:
                added.add(match.id)
                db.add(HospitalDoctor(hospital_id=hospital.id, doctor_id=match.id, department=dept))
        for d in local:  # everyone else in that governorate joins under their own specialty
            if d.id not in added and len(added) < 6:
                added.add(d.id)
                db.add(HospitalDoctor(hospital_id=hospital.id, doctor_id=d.id, department=d.specialty.name))
        new_hospitals.append(hospital)
    await db.commit()

    # ---- pharmacies with stock
    products = (await db.scalars(select(Product))).all()
    new_pharmacies: list[Pharmacy] = []
    for i, (pname, gov) in enumerate(zip(PHARMACY_NAMES, PHARMACY_GOVS)):
        area = await _place(db, gov)
        full = f"{pname} Pharmacy, {area.key}"
        first, last = _name(i % 3 != 0, used_names)
        owner = await _user(db, email=_email(pname.replace("Al ", "al"), area.key, used_emails), password="Pharmacy@12345",
                            name=f"{first} {last}", roles=[Role.PATIENT, Role.PHARMACY], area=area, phone=f"0122{7000000 + i:07d}",
                            national_id=_nid(700 + i, date(1983, 8, 1 + i)), male=i % 3 != 0, birth=date(1983, 8, 1 + i))
        ph = Pharmacy(owner_id=owner.id, name=full, area_id=area.id, address_description=f"{rng.randint(1, 90)} {area.key} main road",
                      phone=f"0{rng.randint(2, 9)}{rng.randint(10000000, 99999999)}", accepted=True)
        db.add(ph)
        await db.flush()
        seen = set()
        for p in rng.sample(products, k=int(len(products) * rng.uniform(.55, .85))):
            if p.drug_id in seen:
                continue
            seen.add(p.drug_id)
            db.add(PharmacyDrug(pharmacy_id=ph.id, drug_id=p.drug_id, quantity=rng.choice([0, 2, 5, 10, 18, 30, 60, 100]),
                                price=Decimal(str(round(float(p.price_egp) * rng.uniform(.95, 1.12), 2)))))
        new_pharmacies.append(ph)
    await db.commit()

    # ---- patients (about one in seven is a child, booked by a parent)
    new_patients: list[tuple[User, bool]] = []
    for i, gov in enumerate(PATIENT_GOVS):
        male = rng.random() < .5
        child = rng.random() < .15
        first, last = _name(male, used_names)
        birth = (date(today.year - rng.randint(2, 14), rng.randint(1, 12), rng.randint(1, 28)) if child
                 else date(today.year - rng.randint(18, 84), rng.randint(1, 12), rng.randint(1, 28)))
        user = await _user(db, email=_email(first, last, used_emails), password="Patient@12345", name=f"{first} {last}", roles=[Role.PATIENT],
                           area=await _place(db, gov), phone=f"01{rng.choice([0, 1, 2, 5])}{8000000 + i:08d}"[:11],
                           national_id=_nid(1000 + i, birth), male=male, birth=birth)
        new_patients.append((user, child))
    await db.commit()

    # ---- a year of care: visits, follow-ups, records, prescriptions, cancelled visits and reviews
    drugs = {d.name.lower(): d for d in (await db.scalars(select(Drug))).all()}
    taken = {(a.doctor_id, a.day, a.time_from.hour) for a in (await db.scalars(select(Appointment).where(Appointment.status == "booked"))).all()}
    reviewed: set[tuple] = set(tuple(r) for r in (await db.execute(select(Review.doctor_id, Review.patient_id))).all())
    recent_prescriptions: list[tuple[User, Doctor, str]] = []

    def pick_doctor(spec: str, gov: str) -> Doctor:
        same = [d for d in doctors_by_spec.get(spec, []) if gov_of_area.get(d.area_id) == gov]
        return rng.choice(same or doctors_by_spec.get(spec) or all_doctors)

    sessions = 0
    for user, child in new_patients:
        gov = gov_of_area.get(user.area_id, "Cairo")
        pool = CHILD_CONDITIONS if child else ADULT_CONDITIONS
        names = [c for c in pool if not (c in ("Pregnancy follow-up", "Polycystic ovary syndrome") and user.gender_male)
                 and not (c == "Benign prostatic hyperplasia" and not user.gender_male)]
        for cond in rng.sample(names, k=rng.choice([1, 2, 2, 3])):
            spec, ingredients, chronic = pool[cond]
            doctor = pick_doctor(spec, gov)
            first_visit = now - timedelta(days=rng.randint(20, 380))
            db.add(Disease(patient_id=user.id, name=cond, persistent=chronic, cured=not chronic and rng.random() < .75,
                           responsible_doctor_id=doctor.id, notes=None))
            visits = [first_visit]
            if chronic:  # follow-ups every 2 to 4 months until now
                t = first_visit
                while True:
                    t += timedelta(days=rng.randint(60, 120))
                    if t > now - timedelta(days=3):
                        break
                    visits.append(t)
            for n, when in enumerate(visits):
                session = MedicalSession(doctor_id=doctor.id, patient_id=user.id, session_date=when, disease_name=cond,
                                         notes=_first_notes(cond) if n == 0 else _follow_up_notes(cond))
                db.add(session)
                await db.flush()
                sessions += 1
                if n == 0:
                    for ing in ingredients:
                        drug = drugs.get(ing)
                        if not drug:
                            continue
                        repeat = "once a week" if ing in ("cholecalciferol", "methotrexate") else rng.choice(["daily", "daily", "every 12 hours", "every 8 hours"])
                        db.add(Prescription(session_id=session.id, drug_id=drug.id, repeat=repeat, repeat_count=REPEATS[repeat],
                                            note=rng.choice(PRESCRIPTION_NOTES), start_date=when.date(),
                                            end_date=when.date() + timedelta(days=3650 if chronic else rng.choice([5, 7, 10, 14]))))
                    if (now - when).days < 30:
                        recent_prescriptions.append((user, doctor, cond))
                db.add(Appointment(patient_id=user.id, doctor_id=doctor.id, day=when.date(), time_from=time(rng.randint(10, 20)), status="done"))
            if (doctor.id, user.id) not in reviewed and rng.random() < .55:
                reviewed.add((doctor.id, user.id))
                arabic = rng.random() < .45
                db.add(Review(doctor_id=doctor.id, patient_id=user.id, rate=Decimal(str(rng.choice([3, 3.5, 4, 4, 4.5, 4.5, 5, 5, 5]))),
                              message=rng.choice(REVIEWS_AR if arabic else REVIEWS_EN), sent_at=visits[0] + timedelta(days=1)))
        if rng.random() < .25:  # a visit that was cancelled
            doctor = rng.choice(all_doctors)
            db.add(Appointment(patient_id=user.id, doctor_id=doctor.id, day=today - timedelta(days=rng.randint(3, 90)),
                               time_from=time(rng.randint(10, 19)), status="cancelled"))
    await db.commit()

    # ---- upcoming bookings over the next three weeks, on each doctor's real hours
    # The main demo doctor (doctor@) is left out here and only gets afternoon visits below:
    # his mornings stay free for people trying the booking flow (and for the tests).
    main_doctor = await db.scalar(select(Doctor).join(User, User.id == Doctor.user_id).where(User.email == "doctor@healthhub.local"))
    upcoming: list[tuple[User, Doctor, date, int]] = []
    for user, child in new_patients:
        for _ in range(rng.choice([0, 1, 1, 1, 2])):
            gov = gov_of_area.get(user.area_id, "Cairo")
            others = [d for d in all_doctors if d.id != main_doctor.id]
            local = [d for d in others if gov_of_area.get(d.area_id) == gov]
            doctor = rng.choice(local or others)
            for _try in range(12):
                day = today + timedelta(days=rng.randint(0, 21))
                hour = await _free_hour(db, doctor, day, taken)
                if hour is not None:
                    db.add(Appointment(patient_id=user.id, doctor_id=doctor.id, day=day, time_from=time(hour), status="booked"))
                    upcoming.append((user, doctor, day, hour))
                    break
    # the main demo doctor gets a fuller week of afternoon visits, so his home screen is busy
    for user, _ in rng.sample(new_patients, k=8):
        for _try in range(10):
            day = today + timedelta(days=rng.randint(0, 6))
            hour = await _free_hour(db, main_doctor, day, taken, from_hour=13)
            if hour is not None:
                db.add(Appointment(patient_id=user.id, doctor_id=main_doctor.id, day=day, time_from=time(hour), status="booked"))
                upcoming.append((user, main_doctor, day, hour))
                break
    await db.commit()

    # ---- conversations
    users_by_id = {u.id: u for u in (await db.scalars(select(User))).all()}
    support = await db.scalar(select(User).where(User.email == "support@healthhub.local"))
    chats = 0
    for n, (user, doctor, day, hour) in enumerate(rng.sample(upcoming, k=min(40, len(upcoming)))):
        subject, lines = PATIENT_DOCTOR_CHATS[n % len(PATIENT_DOCTOR_CHATS)]
        doc_user = users_by_id[doctor.user_id]
        chats += await _chat(db, user, doc_user, subject, lines, {"p": user, "d": doc_user}, now - timedelta(days=rng.randint(0, 6), hours=rng.randint(1, 12)),
                             {"patient": user.name.split()[0]})
    stock = {}
    for pd, brand in (await db.execute(select(PharmacyDrug, Product.brand).join(Product, Product.drug_id == PharmacyDrug.drug_id).where(PharmacyDrug.quantity > 0))).all():
        stock.setdefault(pd.pharmacy_id, []).append((brand, pd.price))
    pharmacies = (await db.scalars(select(Pharmacy).where(Pharmacy.accepted.is_(True)))).all()
    for n, (user, _) in enumerate(rng.sample(new_patients, k=24)):
        gov = gov_of_area.get(user.area_id)
        local = [p for p in pharmacies if gov_of_area.get(p.area_id) == gov and p.owner_id] or [p for p in pharmacies if p.owner_id]
        ph = rng.choice(local)
        brand, price = rng.choice(stock.get(ph.id) or [("Panadol", Decimal("38"))])
        subject, lines = PATIENT_PHARMACY_CHATS[n % len(PATIENT_PHARMACY_CHATS)]
        owner = users_by_id[ph.owner_id]
        area = (await db.get(Area, user.area_id)).key if user.area_id else "Cairo"
        chats += await _chat(db, user, owner, subject, lines, {"p": user, "ph": owner}, now - timedelta(days=rng.randint(0, 20), hours=rng.randint(1, 20)),
                             {"brand": brand, "price": f"{Decimal(price):.0f}", "area": area})
    for n, hospital in enumerate(new_hospitals):
        staff = (await db.scalars(select(HospitalDoctor).where(HospitalDoctor.hospital_id == hospital.id))).all()
        docs = [users_by_id[(await db.get(Doctor, s.doctor_id)).user_id] for s in staff]
        owner = users_by_id[hospital.owner_id]
        if docs:
            subject, lines = HOSPITAL_DOCTOR_CHATS[n % len(HOSPITAL_DOCTOR_CHATS)]
            chats += await _chat(db, owner, docs[0], subject, lines, {"h": owner, "d": docs[0]}, now - timedelta(days=rng.randint(1, 15)),
                                 {"b": docs[0].name.split()[-1]})
        if len(docs) >= 2:
            subject, lines = COLLEAGUE_CHATS[n % len(COLLEAGUE_CHATS)]
            chats += await _chat(db, docs[0], docs[1], subject, lines, {"a": docs[0], "b": docs[1]}, now - timedelta(days=rng.randint(1, 15)),
                                 {"b": docs[1].name.split()[-1]})
    if support:
        for n, (user, _) in enumerate(rng.sample(new_patients, k=len(SUPPORT_CHATS))):
            subject, lines = SUPPORT_CHATS[n]
            chats += await _chat(db, support, user, subject, lines, {"p": user, "s": support}, now - timedelta(days=rng.randint(0, 10)), {})

    # ---- notifications, so every bell has something
    for user, doctor, day, hour in upcoming:
        doc_name = users_by_id[doctor.user_id].name
        db.add(Notification(user_id=user.id, type=NotificationType.APPOINTMENT_REMINDER, is_read=rng.random() < .3,
                            message=f"Reminder: your visit with Dr. {doc_name} is on {day:%A %d %B} at {time(hour):%I:%M %p}.",
                            created_at=now - timedelta(hours=rng.randint(1, 48))))
        db.add(Notification(user_id=doctor.user_id, type=NotificationType.DOCTOR_SELECTED_DATE, is_read=rng.random() < .5,
                            message=f"{user.name} booked a visit on {day:%A %d %B} at {time(hour):%I:%M %p}.",
                            created_at=now - timedelta(hours=rng.randint(1, 72))))
    for user, doctor, cond in recent_prescriptions:
        db.add(Notification(user_id=user.id, type=NotificationType.NEW_PRESCRIPTION, is_read=rng.random() < .5,
                            message=f"Dr. {users_by_id[doctor.user_id].name} added a prescription for {cond}.",
                            created_at=now - timedelta(days=rng.randint(1, 25))))
    for user, _ in rng.sample(new_patients, k=20):
        db.add(Notification(user_id=user.id, type=NotificationType.RATE_DOCTOR, is_read=False,
                            message="How was your last visit? Rate your doctor to help other patients.", created_at=now - timedelta(days=rng.randint(1, 10))))

    # ---- more applications waiting for the admin
    for i, (name, spec, gov) in enumerate(PENDING_DOCTORS):
        area = await _place(db, gov)
        first, last = name.split(" ", 1)
        user = await _user(db, email=_email(first, last, used_emails), password="Doctor@12345", name=name, roles=[Role.PATIENT], area=area,
                           phone=f"0102{9000000 + i:07d}", national_id=_nid(900 + i, date(1990, 1, 10 + i)), male=first in MALE, birth=date(1990, 1, 10 + i))
        db.add(Doctor(user_id=user.id, specialty_id=(await _specialty(db, spec)).id, area_id=area.id, college_name=COLLEGE[gov],
                      summary_career=rng.choice(SPECIALTIES[spec][1]), address_description=f"{rng.randint(2, 60)} {area.key} St.",
                      accepted=False, price_session=Decimal(SPECIALTIES[spec][0]), graduation_year=date(2015, 6, 1),
                      date_of_request=now - timedelta(days=rng.randint(1, 6))))
    for i, (pname, gov, area_name) in enumerate(PENDING_PHARMACIES):
        area = await _place(db, gov, area_name)
        owner = await _user(db, email=_email("alkarma", area.key, used_emails), password="Pharmacy@12345", name="Hossam Eid", roles=[Role.PATIENT],
                            area=area, phone=f"0122{9500000 + i:07d}", national_id=_nid(950 + i, date(1989, 3, 3)), male=True, birth=date(1989, 3, 3))
        db.add(Pharmacy(owner_id=owner.id, name=pname, area_id=area.id, address_description="Saad Zaghloul St.", phone="0552334455", accepted=False))
    for i, (hname, gov, area_name) in enumerate(PENDING_HOSPITALS):
        area = await _place(db, gov, area_name)
        owner = await _user(db, email=_email("upper.nile", "clinic", used_emails), password="Hospital@12345", name=f"{hname} Manager",
                            roles=[Role.PATIENT], area=area, phone=f"0152{9700000 + i:07d}", national_id=_nid(970 + i, date(1977, 4, 4)), male=False, birth=date(1977, 4, 4))
        db.add(Hospital(owner_id=owner.id, name=hname, area_id=area.id, address_description="Television St.", phone="0952201100",
                        description="Day clinics and a small lab on the East Bank.", accepted=False))
    await db.commit()

    print(f"Extra demo data ready: {len(new_doctors)} doctors (every governorate now has one), {len(new_hospitals)} hospitals, "
          f"{len(new_pharmacies)} pharmacies, {len(new_patients)} patients, {sessions} visits with records, {len(upcoming)} upcoming bookings, "
          f"{chats} conversations, {len(PENDING_DOCTORS) + len(PENDING_PHARMACIES) + len(PENDING_HOSPITALS)} more applications for the admin")
