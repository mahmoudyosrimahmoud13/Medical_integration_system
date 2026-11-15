/** Shapes returned by /api/v1. Kept in one file so screens and tests share them. */

export type Role = 'Patient' | 'Doctor' | 'Pharmacy' | 'Hospital' | 'Admin' | 'CustomerService';
export type Workspace = 'patient' | 'doctor' | 'pharmacy' | 'hospital' | 'admin';

export interface Governorate { id: string; key: string; name_ar?: string | null }
export interface Area { id: string; key: string; governorate_id: string; name_ar?: string | null }
export interface Specialty { id: string; name: string }
export interface Drug { id: string; name: string }
export interface Product {
  id: number; brand: string; drug_id: string; active_ingredient: string; strength: string; form: string; pack: string;
  manufacturer: string; category: string; price_egp: number; prescription_only: boolean;
}

export interface User {
  id: string; name: string; email: string; username: string; phone: string | null; gender: 'male' | 'female';
  birth_date: string | null; age: number | null; image_url: string | null; roles: Role[];
  area: Area | null; governorate: Governorate | null; email_confirmed: boolean;
}
export interface TokenOut { access_token: string; expires_at: string; user: User }

export interface ScheduleDay { day_name: string; time_from: string; time_to: string }
export interface DoctorSummary {
  id: string; name: string; image_url: string | null; phone: string | null; specialty: Specialty; area: Area; governorate: Governorate;
  address_description: string; price_session: number; rating_stars: number; rating_percent: number; review_count: number;
}
export interface Doctor extends DoctorSummary {
  user_id: string; email: string; gender: string; college_name: string; graduation_year: string | null; summary_career: string;
  date_of_join: string | null; schedule: ScheduleDay[]; certificates: string[];
}
export interface DoctorRequest extends Doctor { accepted: boolean; rejected: boolean; date_of_request: string }
export interface DoctorPage { items: DoctorSummary[]; total: number; page: number; page_size: number }
export interface Review { id: string; rate: number; message: string; sent_at: string; patient_name: string }
export interface DoctorStats { total: number; male: number; female: number; male_percentage: number; female_percentage: number; upcoming_appointments: number }
export interface ApplicationStatus { status: 'none' | 'pending' | 'rejected' | 'accepted'; access_token?: string | null }

export interface Person { id: string; name: string; image_url: string | null }
export interface Appointment {
  id: string; day: string; day_name: string; time_from: string; time_to: string; status: string;
  doctor?: (Person & { specialty: string; area: string; governorate: string; area_ar?: string | null; governorate_ar?: string | null; phone: string | null }) | null;
  patient?: (Person & { email: string; phone: string | null; gender: string; age: number | null }) | null;
}
export interface BookedSlot { day: string; day_name: string; time_from: string; time_to: string }

export interface Prescription { id: string; drug_id: string; drug_name: string; note: string | null; repeat: string | null; repeat_count: number; start_date: string | null; end_date: string | null }
export interface Session {
  id: string; session_date: string; disease_name: string; notes: string | null; patient_name: string;
  doctor: Person & { email: string; phone: string | null; specialty: string }; prescriptions: Prescription[];
}
export interface Disease { id: string; name: string; persistent: boolean; cured: boolean; notes: string | null; responsible_doctor: string | null }
export interface CtScan { id: string; url: string; result: string | null; uploaded_at: string }
export interface MedicalRecord { patient: User; diseases: Disease[]; current_prescriptions: Prescription[]; sessions: Session[]; ct_scans: CtScan[] }
export interface InteractionReport { available: boolean; impact: boolean; results: { drugA: string; drugB: string; interacts: boolean | null; interactionType: number | null; description: string }[] }
export interface ShareCode { code: string; expires_at: string }

export interface StockItem { drug_id: string; drug_name: string; quantity: number; price: number }
export interface Pharmacy { id: string; owner_id: string | null; name: string; area: Area; governorate: Governorate; address_description: string; phone: string | null; status: string; item?: StockItem | null }
export interface Hospital {
  id: string; owner_id: string; name: string; description: string; area: Area; governorate: Governorate; address_description: string; phone: string | null; status: string;
  doctors: { doctor: DoctorSummary; department: string }[];
}
export interface AppNotification { id: string; type: string; message: string; link: string | null; is_read: boolean; created_at: string }

export interface Contact { user_id: string; name: string; image_url: string | null; role: string; context: string }
export interface ChatMessage { id: string; sender_id: string; sender_name: string; text: string; sent_at: string; read_at: string | null; mine: boolean }
export interface Conversation { id: string; other: Person; other_role: string; subject: string; last_message: ChatMessage | null; unread: number; last_message_at: string }

export interface PendingRequest { id: string; kind: 'doctor' | 'pharmacy' | 'hospital'; title: string; subtitle: string; details: string[]; files: string[] }

export const workspacesOf = (u: User): Workspace[] => [
  'patient',
  ...(u.roles.includes('Doctor') ? ['doctor' as const] : []),
  ...(u.roles.includes('Pharmacy') ? ['pharmacy' as const] : []),
  ...(u.roles.includes('Hospital') ? ['hospital' as const] : []),
  ...(u.roles.includes('Admin') || u.roles.includes('CustomerService') ? ['admin' as const] : []),
];
