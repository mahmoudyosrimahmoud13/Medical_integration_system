/** Typed functions for every API call the web app makes. */

import { api } from './client';
import type {
  ApplicationStatus, AppNotification, Appointment, Area, BookedSlot, ChatMessage, Contact, Conversation, CtScan, Doctor, DoctorPage,
  DoctorRequest, DoctorStats, Drug, Governorate, Hospital, InteractionReport, MedicalRecord, PendingRequest, Pharmacy, Product,
  Review, ScheduleDay, Session, ShareCode, Specialty, StockItem, TokenOut, User,
} from './types';

export const auth = {
  login: (login: string, password: string) => api.post<TokenOut>('/auth/login', { login, password }),
  register: (body: Record<string, unknown>) => api.post<User>('/auth/register', body),
  me: () => api.get<User>('/users/me'),
  forgot: (email: string) => api.post<{ message: string }>('/auth/forgot-password', { email }),
  reset: (token: string, new_password: string) => api.post<{ message: string }>('/auth/reset-password', { token, new_password }),
  changePassword: (old_password: string, new_password: string) => api.post<{ message: string }>('/auth/change-password', { old_password, new_password }),
  changePhoto: (file: File) => { const f = new FormData(); f.append('image', file); return api.upload<User>('/users/me/photo', f, 'PUT'); },
};

export const catalog = {
  governorates: () => api.get<Governorate[]>('/governorates'),
  areas: (governorateId: string) => api.get<Area[]>(`/governorates/${governorateId}/areas`),
  specialties: () => api.get<Specialty[]>('/specialties'),
  drugs: (q: string) => api.get<Drug[]>('/drugs', { q }),
  products: (params: { q?: string; drug_id?: string; category?: string }) => api.get<Product[]>('/products', params),
  productCategories: () => api.get<string[]>('/products/categories'),
};

export interface DoctorFilter { specialty_id?: string; governorate_id?: string; area_id?: string; name?: string; sort?: 'none' | 'rate' | 'join'; page?: number }
export const doctors = {
  search: (f: DoctorFilter) => api.get<DoctorPage>('/doctors', f as Record<string, unknown>),
  get: (id: string) => api.get<Doctor>(`/doctors/${id}`),
  reviews: (id: string) => api.get<Review[]>(`/doctors/${id}/reviews`),
  review: (id: string, rate: number, message: string) => api.post<Review>(`/doctors/${id}/reviews`, { rate, message }),
  bookedSlots: (id: string, day: string) => api.get<BookedSlot[]>(`/doctors/${id}/booked-slots`, { day }),
};

export const appointments = {
  mine: (upcoming_only = true) => api.get<Appointment[]>('/appointments', { upcoming_only }),
  book: (doctor_id: string, day: string, time_from: string) => api.post<Appointment>('/appointments', { doctor_id, day, time_from }),
  move: (id: string, day: string, time_from: string) => api.put<Appointment>(`/appointments/${id}`, { day, time_from }),
  cancel: (id: string) => api.delete<{ message: string }>(`/appointments/${id}`),
};

export const records = {
  mine: () => api.get<MedicalRecord>('/medical/record'),
  patient: (email: string) => api.get<MedicalRecord>(`/medical/patients/${encodeURIComponent(email)}/record`),
  writeSession: (body: Record<string, unknown>) => api.post<Session>('/medical/sessions', body),
  checkInteractions: (patient_email: string, drug_ids: string[]) => api.post<InteractionReport>('/medical/interactions/check', { patient_email, drug_ids }),
  shareCode: () => api.post<ShareCode>('/medical/share-code'),
  uploadCt: (file: File) => { const f = new FormData(); f.append('file', file); return api.upload<CtScan>('/medical/ct-scans', f); },
};

export const doctorPortal = {
  status: () => api.get<ApplicationStatus>('/doctors/me/status'),
  apply: (form: FormData) => api.upload<ApplicationStatus>('/doctors/apply', form),
  schedule: () => api.get<ScheduleDay[]>('/doctors/me/schedule'),
  saveSchedule: (days: ScheduleDay[]) => api.put<ScheduleDay[]>('/doctors/me/schedule', days),
  setPrice: (price: number) => api.put<{ message: string }>('/doctors/me/price', { price }),
  appointments: (upcoming_only = true) => api.get<Appointment[]>('/doctors/me/appointments', { upcoming_only }),
  cancel: (id: string) => api.delete<{ message: string }>(`/doctors/me/appointments/${id}`),
  stats: () => api.get<DoctorStats>('/doctors/me/stats'),
};

export const pharmacy = {
  mine: () => api.get<ApplicationStatus & { pharmacy: Pharmacy | null }>('/pharmacies/me'),
  apply: (body: Record<string, unknown>) => api.post('/pharmacies/apply', body),
  stock: () => api.get<StockItem[]>('/pharmacies/me/stock'),
  setStock: (drug_id: string, quantity: number, price: number) => api.put<StockItem>('/pharmacies/me/stock', { drug_id, quantity, price }),
  removeStock: (drug_id: string) => api.delete(`/pharmacies/me/stock/${drug_id}`),
  byCode: (code: string) => api.get<{ patient_name: string; prescriptions: MedicalRecord['current_prescriptions'] }>('/pharmacies/me/prescriptions', { code }),
  find: (params: { drug_id?: string; governorate_id?: string; area_id?: string }) => api.get<Pharmacy[]>('/pharmacies', params),
};

export const hospital = {
  mine: () => api.get<ApplicationStatus & { hospital: Hospital | null }>('/hospitals/me'),
  apply: (body: Record<string, unknown>) => api.post('/hospitals/apply', body),
  addDoctor: (doctor_email: string, department: string) => api.post<Hospital>('/hospitals/me/doctors', { doctor_email, department }),
  removeDoctor: (doctorId: string) => api.delete<Hospital>(`/hospitals/me/doctors/${doctorId}`),
  appointments: () => api.get<Appointment[]>('/hospitals/me/appointments'),
  find: (params: { governorate_id?: string; area_id?: string; name?: string } = {}) => api.get<Hospital[]>('/hospitals', params),
  get: (id: string) => api.get<Hospital>(`/hospitals/${id}`),
};

export const notifications = {
  all: () => api.get<AppNotification[]>('/notifications'),
  read: (id: string) => api.post(`/notifications/${id}/read`),
};

export const chat = {
  contacts: () => api.get<Contact[]>('/chat/contacts'),
  conversations: () => api.get<Conversation[]>('/chat/conversations'),
  start: (user_id: string, subject = '', first_message?: string) => api.post<Conversation>('/chat/conversations', { user_id, subject, first_message }),
  messages: (id: string, after?: string) => api.get<ChatMessage[]>(`/chat/conversations/${id}/messages`, { after, limit: 100 }),
  send: (id: string, text: string) => api.post<ChatMessage>(`/chat/conversations/${id}/messages`, { text }),
  unread: () => api.get<{ unread: number }>('/chat/unread'),
};

export const admin = {
  doctorRequests: () => api.get<{ items: DoctorRequest[]; total: number }>('/admin/doctor-requests'),
  reviewDoctor: (id: string, accept: boolean) => api.post(`/admin/doctor-requests/${id}/${accept ? 'accept' : 'reject'}`),
  pharmacyRequests: () => api.get<Pharmacy[]>('/admin/pharmacy-requests'),
  hospitalRequests: () => api.get<Hospital[]>('/admin/hospital-requests'),
  reviewFacility: (kind: 'pharmacy' | 'hospital', id: string, accept: boolean) => api.post(`/admin/${kind}-requests/${id}/${accept ? 'accept' : 'reject'}`),
  pending: async (): Promise<PendingRequest[]> => {
    const [d, p, h] = await Promise.all([admin.doctorRequests(), admin.pharmacyRequests(), admin.hospitalRequests()]);
    return [
      ...d.items.map((x) => ({ id: x.id, kind: 'doctor' as const, title: `Dr. ${x.name}`, subtitle: `${x.specialty.name} · ${x.area.key}`, details: [x.email, x.college_name, x.summary_career].filter(Boolean), files: x.certificates })),
      ...p.map((x) => ({ id: x.id, kind: 'pharmacy' as const, title: x.name, subtitle: `${x.area.key}, ${x.governorate.key}`, details: [x.address_description, x.phone ?? ''].filter(Boolean), files: [] })),
      ...h.map((x) => ({ id: x.id, kind: 'hospital' as const, title: x.name, subtitle: `${x.area.key}, ${x.governorate.key}`, details: [x.address_description, x.phone ?? '', x.description].filter(Boolean), files: [] })),
    ];
  },
  review: (kind: PendingRequest['kind'], id: string, accept: boolean) => (kind === 'doctor' ? admin.reviewDoctor(id, accept) : admin.reviewFacility(kind, id, accept)),
  addRole: (email: string, role: string) => api.post('/admin/roles/add', { email, role }),
  removeRole: (email: string, role: string) => api.post('/admin/roles/remove', { email, role }),
};
