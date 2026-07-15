-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.users (
  id_user integer NOT NULL DEFAULT nextval('users_id_user_seq'::regclass),
  username character varying NOT NULL,
  password character varying NOT NULL,
  jenis_role character varying NOT NULL,
  path_gambar character varying,
  no_hp character varying,
  nama character varying,
  email character varying UNIQUE,
  temp_email character varying,
  email_verification_token character varying,
  email_token_expires_at timestamp without time zone,
  otp_code character varying,
  otp_expires_at timestamp with time zone,
  CONSTRAINT users_pkey PRIMARY KEY (id_user)
);
CREATE TABLE public.superadmin (
  id_superadmin integer NOT NULL DEFAULT nextval('superadmin_id_superadmin_seq'::regclass),
  id_user integer NOT NULL,
  CONSTRAINT superadmin_pkey PRIMARY KEY (id_superadmin),
  CONSTRAINT superadmin_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user)
);
CREATE TABLE public.shops_admin (
  id_shops_admin integer NOT NULL DEFAULT nextval('shops_admin_id_shops_admin_seq'::regclass),
  id_user integer NOT NULL,
  CONSTRAINT shops_admin_pkey PRIMARY KEY (id_shops_admin),
  CONSTRAINT shops_admin_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user)
);
CREATE TABLE public.customers (
  id_customers integer NOT NULL DEFAULT nextval('customers_id_customers_seq'::regclass),
  id_user integer NOT NULL,
  nama character varying,
  alamat text,
  longitude numeric,
  latitude numeric,
  created_at timestamp without time zone DEFAULT now(),
  nomor_hp character varying,
  gender character varying,
  birthday date,
  foto character varying,
  CONSTRAINT customers_pkey PRIMARY KEY (id_customers),
  CONSTRAINT customers_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user)
);
CREATE TABLE public.shops (
  id_shops integer NOT NULL DEFAULT nextval('shops_id_shops_seq'::regclass),
  id_shops_admin integer NOT NULL,
  nm_toko character varying NOT NULL,
  desk_toko text,
  alamat_toko text,
  lat_toko numeric,
  long_toko numeric,
  foto_toko character varying,
  foto_ktp character varying,
  spesialisasi character varying,
  tgl_berdiri date,
  jam_buka time without time zone,
  jam_tutup time without time zone,
  saldo_toko numeric DEFAULT 0,
  status_verifikasi character varying DEFAULT 'pending'::character varying,
  upload_qris character varying,
  alasan_penangguhan text,
  suspended_at timestamp without time zone,
  suspended_by integer,
  jarak_gratis_km numeric DEFAULT 0,
  tarif_per_km numeric DEFAULT 0,
  jarak_maksimal_km numeric DEFAULT 10,
  tarif_per_km_luar_radius numeric DEFAULT 0,
  CONSTRAINT shops_pkey PRIMARY KEY (id_shops),
  CONSTRAINT shops_id_shops_admin_fkey FOREIGN KEY (id_shops_admin) REFERENCES public.shops_admin(id_shops_admin),
  CONSTRAINT shops_suspended_by_fkey FOREIGN KEY (suspended_by) REFERENCES public.superadmin(id_superadmin)
);
CREATE TABLE public.account (
  id_account integer NOT NULL DEFAULT nextval('account_id_account_seq'::regclass),
  id_shops integer NOT NULL,
  nama_bank character varying,
  no_rek character varying,
  atas_nama character varying,
  tipe_pembayaran character varying DEFAULT 'BANK_TRANSFER'::character varying,
  path_qris text,
  is_active boolean DEFAULT true,
  is_default boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT account_pkey PRIMARY KEY (id_account),
  CONSTRAINT account_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.services (
  id_services integer NOT NULL DEFAULT nextval('services_id_services_seq'::regclass),
  id_shops integer NOT NULL,
  nama_layanan character varying NOT NULL,
  harga numeric,
  estimasi_waktu character varying,
  deskripsi text,
  is_active boolean DEFAULT true,
  foto_layanan text,
  CONSTRAINT services_pkey PRIMARY KEY (id_services),
  CONSTRAINT services_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.shop_services (
  id_shop_services integer NOT NULL DEFAULT nextval('shop_services_id_shop_services_seq'::regclass),
  id_shops integer NOT NULL,
  id_services integer NOT NULL,
  CONSTRAINT shop_services_pkey PRIMARY KEY (id_shop_services),
  CONSTRAINT shop_services_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops),
  CONSTRAINT shop_services_id_services_fkey FOREIGN KEY (id_services) REFERENCES public.services(id_services)
);
CREATE TABLE public.staff_profile (
  id_staff_profile integer NOT NULL DEFAULT nextval('staff_profile_id_staff_profile_seq'::regclass),
  id_shops integer NOT NULL,
  nama character varying,
  no_hp character varying,
  email character varying,
  role ARRAY DEFAULT '{}'::text[],
  password text,
  status text DEFAULT 'AKTIF'::text,
  CONSTRAINT staff_profile_pkey PRIMARY KEY (id_staff_profile),
  CONSTRAINT staff_profile_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.staff (
  id_staff integer NOT NULL DEFAULT nextval('staff_id_staff_seq'::regclass),
  id_staff_profile integer NOT NULL,
  id_user integer NOT NULL,
  CONSTRAINT staff_pkey PRIMARY KEY (id_staff),
  CONSTRAINT fk_staff_profile FOREIGN KEY (id_staff_profile) REFERENCES public.staff_profile(id_staff_profile)
);
CREATE TABLE public.cart (
  id_cart integer NOT NULL DEFAULT nextval('cart_id_cart_seq'::regclass),
  id_customers integer NOT NULL,
  id_shops integer NOT NULL,
  status_keranjang character varying DEFAULT 'aktif'::character varying,
  CONSTRAINT cart_pkey PRIMARY KEY (id_cart),
  CONSTRAINT cart_id_customers_fkey FOREIGN KEY (id_customers) REFERENCES public.customers(id_customers),
  CONSTRAINT cart_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.cart_item (
  id_cart_item integer NOT NULL DEFAULT nextval('cart_item_id_cart_item_seq'::regclass),
  id_cart integer NOT NULL,
  id_services integer NOT NULL,
  harga_layanan numeric,
  catatan text,
  merk character varying,
  jenis_sepatu character varying,
  warna character varying,
  foto_sebelum character varying,
  CONSTRAINT cart_item_pkey PRIMARY KEY (id_cart_item),
  CONSTRAINT cart_item_id_cart_fkey FOREIGN KEY (id_cart) REFERENCES public.cart(id_cart),
  CONSTRAINT cart_item_id_services_fkey FOREIGN KEY (id_services) REFERENCES public.services(id_services)
);
CREATE TABLE public.orders (
  id_orders integer NOT NULL DEFAULT nextval('orders_id_orders_seq'::regclass),
  kode_order character varying NOT NULL UNIQUE,
  id_customer integer NOT NULL,
  id_shops integer NOT NULL,
  tgl_order timestamp without time zone DEFAULT now(),
  metode_order character varying,
  metode_bayar character varying,
  upload_bkt_byr character varying,
  alamat_pengantaran text,
  lat_order numeric,
  long_order numeric,
  qr_image character varying,
  link_qr character varying,
  total_ongkir numeric DEFAULT 0,
  status_pembayaran character varying DEFAULT 'unpaid'::character varying,
  catatan_pengiriman text,
  foto_validasi character varying,
  metode_pengambilan text DEFAULT 'pickup'::text,
  status_order USER-DEFINED NOT NULL DEFAULT 'pending'::order_status_enum,
  alasan_tolak_pembayaran text,
  id_staff integer,
  CONSTRAINT orders_pkey PRIMARY KEY (id_orders),
  CONSTRAINT orders_id_customer_fkey FOREIGN KEY (id_customer) REFERENCES public.customers(id_customers),
  CONSTRAINT orders_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops),
  CONSTRAINT orders_id_staff_fkey FOREIGN KEY (id_staff) REFERENCES public.users(id_user)
);
CREATE TABLE public.detail_orders (
  id_detail_orders integer NOT NULL DEFAULT nextval('detail_orders_id_detail_orders_seq'::regclass),
  id_orders integer NOT NULL,
  id_services integer NOT NULL,
  foto_sebelum character varying,
  merk character varying,
  jenis_sepatu character varying,
  warna character varying,
  review text,
  foto_sesudah character varying,
  total_harga numeric,
  catatan character varying,
  CONSTRAINT detail_orders_pkey PRIMARY KEY (id_detail_orders),
  CONSTRAINT detail_orders_id_orders_fkey FOREIGN KEY (id_orders) REFERENCES public.orders(id_orders),
  CONSTRAINT detail_orders_id_services_fkey FOREIGN KEY (id_services) REFERENCES public.services(id_services)
);
CREATE TABLE public.notification (
  id_notification integer NOT NULL DEFAULT nextval('notification_id_notification_seq'::regclass),
  id_user integer NOT NULL,
  title character varying,
  id_orders integer,
  message text,
  type_notification character varying,
  is_read boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT notification_pkey PRIMARY KEY (id_notification),
  CONSTRAINT notification_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user),
  CONSTRAINT notification_id_orders_fkey FOREIGN KEY (id_orders) REFERENCES public.orders(id_orders)
);
CREATE TABLE public.tracking_logs (
  id_tracking_logs integer NOT NULL DEFAULT nextval('tracking_logs_id_tracking_logs_seq'::regclass),
  status character varying,
  id_staff integer,
  id_orders integer NOT NULL,
  waktu timestamp without time zone DEFAULT now(),
  keterangan text,
  latitude numeric,
  longitude numeric,
  log_type character varying DEFAULT 'gps_update'::character varying CHECK (log_type::text = ANY (ARRAY['gps_update'::character varying, 'status_change'::character varying]::text[])),
  CONSTRAINT tracking_logs_pkey PRIMARY KEY (id_tracking_logs),
  CONSTRAINT tracking_logs_id_staff_fkey FOREIGN KEY (id_staff) REFERENCES public.staff(id_staff),
  CONSTRAINT tracking_logs_id_orders_fkey FOREIGN KEY (id_orders) REFERENCES public.orders(id_orders)
);
CREATE TABLE public.inventory (
  id_inventory integer NOT NULL DEFAULT nextval('inventory_id_inventory_seq'::regclass),
  id_shops integer NOT NULL,
  nama_item character varying NOT NULL,
  kategori character varying,
  stok_saat_ini numeric DEFAULT 0,
  stok_maksimum numeric DEFAULT 0,
  stok_minimum numeric DEFAULT 0,
  satuan character varying,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  foto_inven text,
  CONSTRAINT inventory_pkey PRIMARY KEY (id_inventory),
  CONSTRAINT inventory_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.shop_operating_hours (
  id_shop_operating_hours integer NOT NULL DEFAULT nextval('shop_operating_hours_id_shop_operating_hours_seq'::regclass),
  id_shops integer NOT NULL,
  day_of_week smallint NOT NULL CHECK (day_of_week >= 1 AND day_of_week <= 7),
  is_open boolean NOT NULL DEFAULT true,
  open_time time without time zone,
  close_time time without time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT shop_operating_hours_pkey PRIMARY KEY (id_shop_operating_hours),
  CONSTRAINT shop_operating_hours_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops)
);
CREATE TABLE public.ulasan (
  id_ulasan integer NOT NULL DEFAULT nextval('ulasan_id_ulasan_seq'::regclass),
  id_customers integer NOT NULL,
  id_shops integer NOT NULL,
  id_orders integer,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  ulasan text,
  foto_ulasan ARRAY DEFAULT '{}'::text[],
  created_at timestamp with time zone DEFAULT now(),
  id_services integer,
  CONSTRAINT ulasan_pkey PRIMARY KEY (id_ulasan),
  CONSTRAINT ulasan_id_customers_fkey FOREIGN KEY (id_customers) REFERENCES public.customers(id_customers),
  CONSTRAINT ulasan_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops),
  CONSTRAINT ulasan_id_orders_fkey FOREIGN KEY (id_orders) REFERENCES public.orders(id_orders),
  CONSTRAINT ulasan_id_services_fkey FOREIGN KEY (id_services) REFERENCES public.services(id_services)
);
CREATE TABLE public.shop_suspension_appeals (
  id_appeal integer NOT NULL DEFAULT nextval('shop_suspension_appeals_id_appeal_seq'::regclass),
  id_shops integer NOT NULL,
  id_shops_admin integer NOT NULL,
  description text NOT NULL,
  evidence_images ARRAY DEFAULT '{}'::text[],
  status character varying DEFAULT 'pending'::character varying CHECK (status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying]::text[])),
  reviewed_by integer,
  reviewed_at timestamp without time zone,
  rejection_reason text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  CONSTRAINT shop_suspension_appeals_pkey PRIMARY KEY (id_appeal),
  CONSTRAINT shop_suspension_appeals_id_shops_fkey FOREIGN KEY (id_shops) REFERENCES public.shops(id_shops),
  CONSTRAINT shop_suspension_appeals_id_shops_admin_fkey FOREIGN KEY (id_shops_admin) REFERENCES public.shops_admin(id_shops_admin),
  CONSTRAINT shop_suspension_appeals_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.superadmin(id_superadmin)
);
CREATE TABLE public.customer_addresses (
  id_address integer NOT NULL DEFAULT nextval('customer_addresses_id_address_seq'::regclass),
  id_user integer,
  recipient_name character varying NOT NULL,
  phone_number character varying NOT NULL,
  full_address text NOT NULL,
  address_label character varying,
  is_default boolean DEFAULT false,
  created_at timestamp without time zone DEFAULT now(),
  latitude numeric,
  longitude numeric,
  CONSTRAINT customer_addresses_pkey PRIMARY KEY (id_address),
  CONSTRAINT customer_addresses_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user)
);
CREATE TABLE public.user_fcm_tokens (
  id_fcm_token bigint NOT NULL DEFAULT nextval('user_fcm_tokens_id_fcm_token_seq'::regclass),
  id_user integer NOT NULL,
  fcm_token text NOT NULL UNIQUE,
  platform character varying,
  device_id text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_fcm_tokens_pkey PRIMARY KEY (id_fcm_token),
  CONSTRAINT user_fcm_tokens_id_user_fkey FOREIGN KEY (id_user) REFERENCES public.users(id_user)
);
CREATE TABLE public.order_status_history (
  id_history integer NOT NULL DEFAULT nextval('order_status_history_id_history_seq'::regclass),
  id_orders integer NOT NULL,
  id_staff integer,
  status USER-DEFINED NOT NULL,
  keterangan text,
  changed_by_role character varying CHECK (changed_by_role::text = ANY (ARRAY['admin_toko'::character varying, 'staff'::character varying, 'customer'::character varying, 'system'::character varying]::text[])),
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT order_status_history_pkey PRIMARY KEY (id_history),
  CONSTRAINT order_status_history_id_orders_fkey FOREIGN KEY (id_orders) REFERENCES public.orders(id_orders),
  CONSTRAINT order_status_history_id_staff_fkey FOREIGN KEY (id_staff) REFERENCES public.staff(id_staff)
);