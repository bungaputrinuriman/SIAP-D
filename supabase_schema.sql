-- ==============================================================================
-- SUPABASE SCHEMA MIGRATION: SI-PKL DISKOMINFO
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. CREATE TABLES
-- ==============================================================================

-- A. Fields (Bidang)
CREATE TABLE public.fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'Aktif',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- B. Divisions (Divisi)
CREATE TABLE public.divisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    field_id UUID NOT NULL REFERENCES public.fields(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'Aktif',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- C. Supervisors (Pembimbing Lapangan)
CREATE TABLE public.supervisors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    field_id UUID REFERENCES public.fields(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'Aktif',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- D. Profiles
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'peserta')),
    nim TEXT,
    university TEXT,
    study_program TEXT,
    field_id UUID REFERENCES public.fields(id) ON DELETE SET NULL,
    division_id UUID REFERENCES public.divisions(id) ON DELETE SET NULL,
    supervisor_id UUID REFERENCES public.supervisors(id) ON DELETE SET NULL,
    start_date DATE,
    end_date DATE,
    status TEXT DEFAULT 'Aktif',
    photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- E. Attendance (Presensi)
CREATE TABLE public.attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('Hadir', 'Izin', 'Sakit')),
    check_in_time TIMESTAMPTZ,
    check_out_time TIMESTAMPTZ,
    reason TEXT,
    check_in_photo_url TEXT,
    check_in_signature_url TEXT,
    check_out_photo_url TEXT,
    check_out_signature_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT unique_user_date UNIQUE (user_id, date) -- Mencegah record ganda
);

-- F. Notifications (Notifikasi)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==============================================================================
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ==============================================================================

ALTER TABLE public.fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.divisions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supervisors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 4. RLS POLICIES
-- ==============================================================================

-- Helper Function: Cek apakah user yang login adalah admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- A. Fields Policies
-- Semua orang bisa melihat bidang (untuk keperluan form pendaftaran/filter)
CREATE POLICY "Anyone can view fields" ON public.fields FOR SELECT USING (true);
-- Hanya admin yang bisa mengubah/menambah bidang
CREATE POLICY "Admin can manage fields" ON public.fields FOR ALL USING (public.is_admin());

-- B. Divisions Policies
CREATE POLICY "Anyone can view divisions" ON public.divisions FOR SELECT USING (true);
CREATE POLICY "Admin can manage divisions" ON public.divisions FOR ALL USING (public.is_admin());

-- C. Supervisors Policies
CREATE POLICY "Anyone can view supervisors" ON public.supervisors FOR SELECT USING (true);
CREATE POLICY "Admin can manage supervisors" ON public.supervisors FOR ALL USING (public.is_admin());

-- D. Profiles Policies
-- Peserta hanya bisa melihat profilnya sendiri
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
-- Peserta bisa insert profilnya sendiri saat register
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
-- Peserta bisa meng-update profilnya sendiri (opsional)
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
-- Admin bisa melakukan apapun terhadap tabel profil
CREATE POLICY "Admin can view all profiles" ON public.profiles FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin can insert profiles" ON public.profiles FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "Admin can update profiles" ON public.profiles FOR UPDATE USING (public.is_admin());
CREATE POLICY "Admin can delete profiles" ON public.profiles FOR DELETE USING (public.is_admin());

-- E. Attendance Policies
-- Peserta hanya bisa melihat presensinya sendiri
CREATE POLICY "Users can view own attendance" ON public.attendance FOR SELECT USING (auth.uid() = user_id);
-- Peserta hanya bisa insert/update presensinya sendiri
CREATE POLICY "Users can insert own attendance" ON public.attendance FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own attendance" ON public.attendance FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
-- Admin bisa melakukan apapun terhadap tabel presensi
CREATE POLICY "Admin can manage attendance" ON public.attendance FOR ALL USING (public.is_admin());

-- F. Notifications Policies
-- Semua user yang login (seperti peserta) dapat mengirim notifikasi ke pembimbing
CREATE POLICY "Allow authenticated users to insert notifications" 
ON public.notifications FOR INSERT TO authenticated WITH CHECK (true);

-- Pembimbing hanya dapat melihat notifikasi yang ditujukan untuk dirinya
CREATE POLICY "Users can view own notifications" 
ON public.notifications FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Pembimbing dapat meng-update status is_read notifikasinya
CREATE POLICY "Users can update own notifications" 
ON public.notifications FOR UPDATE TO authenticated USING (auth.uid() = user_id);

-- Pembimbing dapat menghapus notifikasi miliknya
CREATE POLICY "Users can delete own notifications" 
ON public.notifications FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- Admin dapat mengelola semua notifikasi
CREATE POLICY "Admin can manage all notifications" 
ON public.notifications FOR ALL TO authenticated USING (public.is_admin());

-- ==============================================================================
-- 5. STORAGE BUCKETS
-- ==============================================================================
-- Pastikan Anda juga membuat bucket Supabase Storage bernama 'photos' dan 'signatures'
-- melalui dashboard Supabase, dengan menjadikannya Public (agar dapat diakses dari URL).

