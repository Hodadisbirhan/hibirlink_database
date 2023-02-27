SET check_function_bodies = false;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';
CREATE TABLE public.digital_product (
    id integer NOT NULL,
    title character varying NOT NULL,
    "demoLink" text NOT NULL,
    unit_price numeric NOT NULL,
    discount_id bigint,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    supplier_id character varying NOT NULL,
    cover_image text NOT NULL,
    category_id integer NOT NULL,
    description jsonb NOT NULL,
    CONSTRAINT "price is morethan zero" CHECK ((unit_price > (0)::numeric))
);
CREATE FUNCTION public.average_digitalproduct_rate(_product public.digital_product) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
select avg(rate) from digital_product_rate where product_id = _product.id;
$$;
CREATE TABLE public.physical_product (
    id bigint NOT NULL,
    supplier_id character varying NOT NULL,
    title character varying NOT NULL,
    unit_price numeric NOT NULL,
    status character varying NOT NULL,
    category_id integer,
    sub_category_id integer,
    cover_image text NOT NULL,
    discount_id integer,
    description jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    amount integer NOT NULL,
    CONSTRAINT "quantity should be more than zero" CHECK ((amount >= 0)),
    CONSTRAINT "unit_price should be greater than zero" CHECK ((unit_price > (0)::numeric))
);
CREATE FUNCTION public.average_pproduct_rate(_product public.physical_product) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
select avg(rating) from physical_product_rate where product_id = _product.id;
$$;
CREATE TABLE public.realtime_service (
    id bigint NOT NULL,
    title character varying NOT NULL,
    logo text NOT NULL,
    "tinNumber" character varying,
    licence text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    category_id integer NOT NULL,
    service_owner character varying NOT NULL,
    "isVerified" boolean DEFAULT false NOT NULL,
    discount_id integer,
    "accountID" integer,
    description jsonb NOT NULL,
    avaliability jsonb NOT NULL
);
CREATE FUNCTION public.average_rate(_realtime public.realtime_service) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  select avg(rate) from realtime_service_rate where service_id = _realtime.id;
$$;
CREATE FUNCTION public.discount_fun(rate numeric, start_date date, end_date date, reason jsonb, productid integer) RETURNS SETOF public.physical_product
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE disID integer;
  begin
  insert into product_discount(rate,reason,start_date,end_date) values(rate,reason,start_date,end_date) returning id  into disID;
  update physical_product set discount_id = disID where id = productId;
   return query select * from physical_product;
  end;
    $$;
CREATE TABLE public.service_discount (
    id integer NOT NULL,
    rate numeric NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    reason jsonb NOT NULL
);
CREATE FUNCTION public.insert_service_discount_function(serviceid integer, enddate date, startdate date, rate numeric, reason jsonb) RETURNS SETOF public.service_discount
    LANGUAGE plpgsql
    AS $$
 declare discountid integer; name text;
 begin
 insert into service_discount(start_date,end_date,rate,reason) values (startdate,enddate,rate,reason)  returning id into discountid ;
update realtime_service set discount_id = discountid where id = serviceid returning title into name;
if name is not null and name != '' then 
return query select * from service_discount where id = discountid;
else
raise exception using errcode='no service error', message='anonymous discount is forbiden';
end if;
end;
 $$;
CREATE FUNCTION public.set_current_timestamp_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  _new record;
BEGIN
  _new := NEW;
  _new."updated_at" = NOW();
  RETURN _new;
END;
$$;
CREATE TABLE public.virtual_service (
    id integer NOT NULL,
    title character varying NOT NULL,
    license text,
    logo text NOT NULL,
    category_id integer NOT NULL,
    account_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    service_owner character varying NOT NULL,
    is_verified boolean DEFAULT false NOT NULL,
    discount_id integer,
    web_link character varying,
    description jsonb NOT NULL
);
CREATE FUNCTION public.total_rate(_virtualservice public.virtual_service) RETURNS numeric
    LANGUAGE sql STABLE
    AS $$
  select avg(rate) from virtual_service_rate where service_id = _virtualservice.id;
$$;
CREATE TABLE public.users (
    id character varying NOT NULL,
    "firstName" character varying NOT NULL,
    "lastName" character varying NOT NULL,
    email character varying NOT NULL,
    role text DEFAULT 'customer'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);
CREATE FUNCTION public.total_realtime_service(user_row public.users) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
 select count(*) from  realtime_service where  service_Owner = user_row.id;
 $$;
CREATE TABLE public.virtual_service_category (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE FUNCTION public.total_service(_virtualservicecategory public.virtual_service_category) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
  select count(*)  from virtual_service where category_id = _virtualservicecategory.id;
$$;
CREATE TABLE public.account (
    id integer NOT NULL,
    "accountNumber" character varying NOT NULL,
    "accountHolder" character varying NOT NULL,
    "accountType" character varying NOT NULL
);
CREATE SEQUENCE public.acount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.acount_id_seq OWNED BY public.account.id;
CREATE TABLE public.physical_product_rate (
    product_id integer NOT NULL,
    rating integer NOT NULL,
    "user_Id" character varying NOT NULL,
    CONSTRAINT author_rating_check CHECK (((rating > 0) AND (rating <= 5)))
);
CREATE SEQUENCE public.author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.author_id_seq OWNED BY public.physical_product_rate.product_id;
CREATE TABLE public.digital_product_category (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE public.digital_product_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.digital_product_category_id_seq OWNED BY public.digital_product_category.id;
CREATE SEQUENCE public.digital_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.digital_product_id_seq OWNED BY public.digital_product.id;
CREATE TABLE public.digital_product_image (
    id integer NOT NULL,
    "imageUrl" text NOT NULL,
    "productID" integer NOT NULL
);
CREATE SEQUENCE public.digital_product_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.digital_product_image_id_seq OWNED BY public.digital_product_image.id;
CREATE TABLE public.digital_product_rate (
    product_id integer NOT NULL,
    user_id character varying NOT NULL,
    rate integer NOT NULL,
    CONSTRAINT check_rate CHECK (((rate > 0) AND (rate <= 5)))
);
CREATE TABLE public.product_discount (
    id integer NOT NULL,
    rate numeric NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    reason jsonb,
    CONSTRAINT "rate_greaterthan _ero" CHECK ((rate > (0)::numeric))
);
CREATE SEQUENCE public.discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.discount_id_seq OWNED BY public.product_discount.id;
CREATE VIEW public.new_release_digital_product AS
SELECT
    NULL::character varying AS title,
    NULL::integer AS id,
    NULL::text AS cover_image,
    NULL::jsonb AS description,
    NULL::integer AS category_id,
    NULL::numeric AS average_rate,
    NULL::numeric AS unit_price,
    NULL::timestamp with time zone AS created_at,
    NULL::timestamp with time zone AS updated_at;
CREATE VIEW public.new_release_realtime_product AS
SELECT
    NULL::character varying AS title,
    NULL::bigint AS id,
    NULL::text AS cover_image,
    NULL::jsonb AS description,
    NULL::integer AS category_id,
    NULL::integer AS sub_category_id,
    NULL::numeric AS average_rate,
    NULL::integer AS amount,
    NULL::numeric AS unit_price,
    NULL::timestamp with time zone AS created_at,
    NULL::timestamp with time zone AS updated_at,
    NULL::character varying AS status,
    NULL::integer AS discount_id;
CREATE TABLE public.order_detail (
    id bigint NOT NULL,
    "productID" integer NOT NULL,
    "orderID" integer NOT NULL,
    quantity integer NOT NULL,
    "unitPrice" numeric NOT NULL
);
CREATE SEQUENCE public.order_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.order_detail_id_seq OWNED BY public.order_detail.id;
CREATE TABLE public.order_status (
    value text NOT NULL,
    description text NOT NULL
);
INSERT INTO order_status(value,description) values("completed","the order is  already completed");
CREATE TABLE public.physical_product_category (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE public.physical_product_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.physical_product_category_id_seq OWNED BY public.physical_product_category.id;
CREATE SEQUENCE public.physical_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.physical_product_id_seq OWNED BY public.physical_product.id;
CREATE TABLE public.physical_product_image (
    id integer NOT NULL,
    product_id integer NOT NULL,
    image_url text NOT NULL
);
CREATE SEQUENCE public.physical_product_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.physical_product_image_id_seq OWNED BY public.physical_product_image.id;
CREATE TABLE public.physical_product_subcategory (
    id integer NOT NULL,
    name character varying NOT NULL,
    category_id integer NOT NULL
);
CREATE SEQUENCE public.physical_product_subcategory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.physical_product_subcategory_id_seq OWNED BY public.physical_product_subcategory.id;
CREATE TABLE public.product_address (
    id integer NOT NULL,
    city character varying NOT NULL,
    sub_city character varying NOT NULL,
    description jsonb NOT NULL,
    product_id integer NOT NULL
);
CREATE SEQUENCE public.product_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.product_address_id_seq OWNED BY public.product_address.id;
CREATE TABLE public.product_order (
    id integer NOT NULL,
    "customerID" character varying NOT NULL,
    status text NOT NULL,
    "transactionPrimaryKey" text NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    "withDelivery" boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE public.product_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.product_order_id_seq OWNED BY public.product_order.id;
CREATE TABLE public.product_status (
    value text NOT NULL,
    description text NOT NULL
);
CREATE TABLE public.realtime_service_address (
    id integer NOT NULL,
    "serviceID" integer NOT NULL,
    "phoneNumber" character varying NOT NULL,
    "socialMedia" jsonb,
    region_city character varying NOT NULL,
    subcity character varying NOT NULL,
    description jsonb NOT NULL
);
CREATE SEQUENCE public.realtime_service_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.realtime_service_address_id_seq OWNED BY public.realtime_service_address.id;
CREATE TABLE public.realtime_service_category (
    id integer NOT NULL,
    name character varying NOT NULL
);
CREATE SEQUENCE public.realtime_service_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.realtime_service_category_id_seq OWNED BY public.realtime_service_category.id;
CREATE SEQUENCE public.realtime_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.realtime_service_id_seq OWNED BY public.realtime_service.id;
CREATE TABLE public.realtime_service_image (
    id integer NOT NULL,
    "imageURL" text NOT NULL,
    "serviceID" integer NOT NULL
);
CREATE SEQUENCE public.realtime_service_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.realtime_service_image_id_seq OWNED BY public.realtime_service_image.id;
CREATE TABLE public.realtime_service_rate (
    user_id character varying NOT NULL,
    service_id integer NOT NULL,
    rate integer NOT NULL,
    CONSTRAINT check_rate_value CHECK (((rate > 0) AND (rate <= 5)))
);
CREATE TABLE public.role (
    name text NOT NULL,
    description text
);
CREATE SEQUENCE public.service_discount_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.service_discount_id_seq OWNED BY public.service_discount.id;
CREATE TABLE public.shipping_address (
    "orderID" bigint NOT NULL,
    "locationName" character varying NOT NULL,
    discription text NOT NULL,
    longitude numeric NOT NULL,
    latitude numeric NOT NULL
);
CREATE SEQUENCE public.shipping_address_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.shipping_address_id_seq OWNED BY public.shipping_address."orderID";
CREATE TABLE public.shopping_cart (
    "productID" integer NOT NULL,
    "userID" character varying NOT NULL,
    "createAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL,
    quantity integer NOT NULL
);
CREATE TABLE public.supplier (
    id character varying NOT NULL,
    "storeName" character varying,
    "phoneNumber" character varying NOT NULL,
    "accountNumber" character varying NOT NULL,
    "tinNumber" character varying,
    "socialMedia" jsonb
);
CREATE TABLE public.supplier_address (
    id integer NOT NULL,
    "supplierID" character varying NOT NULL,
    description jsonb NOT NULL,
    "regionOrCity" character varying NOT NULL,
    "subCity" character varying NOT NULL
);
CREATE SEQUENCE public.supplier_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.supplier_address_id_seq OWNED BY public.supplier_address.id;
CREATE TABLE public.supplier_status (
    value text NOT NULL,
    description text NOT NULL
);
CREATE TABLE public.supplier_varified_by (
    "userID" character varying NOT NULL,
    "supplierID" character varying NOT NULL,
    status text NOT NULL,
    reason text NOT NULL,
    CONSTRAINT you_have_no_todo_with_yourself CHECK ((status > reason))
);
CREATE TABLE public.user_physical_product_history (
    id uuid NOT NULL,
    user_id character varying NOT NULL,
    product_id bigint NOT NULL,
    product_title character varying NOT NULL,
    product_rating integer NOT NULL,
    product_unit_price numeric NOT NULL,
    product_status character varying NOT NULL,
    product_category character varying NOT NULL,
    product_sub_category character varying NOT NULL,
    product_city character varying NOT NULL,
    product_sub_city character varying NOT NULL,
    product_licenced boolean NOT NULL
);
COMMENT ON TABLE public.user_physical_product_history IS 'user''s physical product data mining.';
CREATE SEQUENCE public.user_physical_product_history_product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.user_physical_product_history_product_id_seq OWNED BY public.user_physical_product_history.product_id;
CREATE TABLE public.user_realtime_service_history (
    id uuid NOT NULL,
    user_id character varying NOT NULL,
    service_id bigint NOT NULL,
    service_title character varying NOT NULL,
    service_rating integer NOT NULL,
    service_category character varying NOT NULL,
    service_city character varying NOT NULL,
    service_sub_city character varying NOT NULL,
    service_verification boolean NOT NULL
);
COMMENT ON TABLE public.user_realtime_service_history IS 'user''s realtime service data mining.';
CREATE TABLE public.virtual_service_address (
    id integer NOT NULL,
    service_id integer NOT NULL,
    description jsonb NOT NULL,
    social_media jsonb NOT NULL,
    phone_number character varying NOT NULL
);
CREATE SEQUENCE public.virtual_service_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.virtual_service_address_id_seq OWNED BY public.virtual_service_address.id;
CREATE SEQUENCE public.virtual_service_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.virtual_service_category_id_seq OWNED BY public.virtual_service_category.id;
CREATE SEQUENCE public.virtual_service_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.virtual_service_id_seq OWNED BY public.virtual_service.id;
CREATE TABLE public.virtual_service_image (
    id integer NOT NULL,
    image_url text NOT NULL,
    service_id integer NOT NULL
);
CREATE SEQUENCE public.virtual_service_image_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.virtual_service_image_id_seq OWNED BY public.virtual_service_image.id;
CREATE TABLE public.virtual_service_rate (
    rate integer NOT NULL,
    user_id character varying NOT NULL,
    service_id integer NOT NULL,
    CONSTRAINT check_rate_value CHECK (((rate > 0) AND (rate <= 5)))
);
ALTER TABLE ONLY public.account ALTER COLUMN id SET DEFAULT nextval('public.acount_id_seq'::regclass);
ALTER TABLE ONLY public.digital_product ALTER COLUMN id SET DEFAULT nextval('public.digital_product_id_seq'::regclass);
ALTER TABLE ONLY public.digital_product_category ALTER COLUMN id SET DEFAULT nextval('public.digital_product_category_id_seq'::regclass);
ALTER TABLE ONLY public.digital_product_image ALTER COLUMN id SET DEFAULT nextval('public.digital_product_image_id_seq'::regclass);
ALTER TABLE ONLY public.order_detail ALTER COLUMN id SET DEFAULT nextval('public.order_detail_id_seq'::regclass);
ALTER TABLE ONLY public.physical_product ALTER COLUMN id SET DEFAULT nextval('public.physical_product_id_seq'::regclass);
ALTER TABLE ONLY public.physical_product_category ALTER COLUMN id SET DEFAULT nextval('public.physical_product_category_id_seq'::regclass);
ALTER TABLE ONLY public.physical_product_image ALTER COLUMN id SET DEFAULT nextval('public.physical_product_image_id_seq'::regclass);
ALTER TABLE ONLY public.physical_product_subcategory ALTER COLUMN id SET DEFAULT nextval('public.physical_product_subcategory_id_seq'::regclass);
ALTER TABLE ONLY public.product_address ALTER COLUMN id SET DEFAULT nextval('public.product_address_id_seq'::regclass);
ALTER TABLE ONLY public.product_discount ALTER COLUMN id SET DEFAULT nextval('public.discount_id_seq'::regclass);
ALTER TABLE ONLY public.product_order ALTER COLUMN id SET DEFAULT nextval('public.product_order_id_seq'::regclass);
ALTER TABLE ONLY public.realtime_service ALTER COLUMN id SET DEFAULT nextval('public.realtime_service_id_seq'::regclass);
ALTER TABLE ONLY public.realtime_service_address ALTER COLUMN id SET DEFAULT nextval('public.realtime_service_address_id_seq'::regclass);
ALTER TABLE ONLY public.realtime_service_category ALTER COLUMN id SET DEFAULT nextval('public.realtime_service_category_id_seq'::regclass);
ALTER TABLE ONLY public.realtime_service_image ALTER COLUMN id SET DEFAULT nextval('public.realtime_service_image_id_seq'::regclass);
ALTER TABLE ONLY public.service_discount ALTER COLUMN id SET DEFAULT nextval('public.service_discount_id_seq'::regclass);
ALTER TABLE ONLY public.shipping_address ALTER COLUMN "orderID" SET DEFAULT nextval('public.shipping_address_id_seq'::regclass);
ALTER TABLE ONLY public.supplier_address ALTER COLUMN id SET DEFAULT nextval('public.supplier_address_id_seq'::regclass);
ALTER TABLE ONLY public.virtual_service ALTER COLUMN id SET DEFAULT nextval('public.virtual_service_id_seq'::regclass);
ALTER TABLE ONLY public.virtual_service_address ALTER COLUMN id SET DEFAULT nextval('public.virtual_service_address_id_seq'::regclass);
ALTER TABLE ONLY public.virtual_service_category ALTER COLUMN id SET DEFAULT nextval('public.virtual_service_category_id_seq'::regclass);
ALTER TABLE ONLY public.virtual_service_image ALTER COLUMN id SET DEFAULT nextval('public.virtual_service_image_id_seq'::regclass);
ALTER TABLE ONLY public.account
    ADD CONSTRAINT acount_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.digital_product_category
    ADD CONSTRAINT digital_product_category_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.digital_product_image
    ADD CONSTRAINT digital_product_image_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.digital_product
    ADD CONSTRAINT digital_product_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.digital_product_rate
    ADD CONSTRAINT digital_product_rate_pkey PRIMARY KEY (product_id, user_id);
ALTER TABLE ONLY public.product_discount
    ADD CONSTRAINT discount_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.order_detail
    ADD CONSTRAINT order_detail_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.order_status
    ADD CONSTRAINT order_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.physical_product_category
    ADD CONSTRAINT physical_product_category_name_key UNIQUE (name);
ALTER TABLE ONLY public.physical_product_category
    ADD CONSTRAINT physical_product_category_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.physical_product_image
    ADD CONSTRAINT physical_product_image_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT physical_product_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.physical_product_rate
    ADD CONSTRAINT physical_product_rate_pkey PRIMARY KEY (product_id, "user_Id");
ALTER TABLE ONLY public.physical_product_subcategory
    ADD CONSTRAINT physical_product_subcategory_name_key UNIQUE (name);
ALTER TABLE ONLY public.physical_product_subcategory
    ADD CONSTRAINT physical_product_subcategory_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.product_status
    ADD CONSTRAINT "productStatus_pkey" PRIMARY KEY (value);
ALTER TABLE ONLY public.product_address
    ADD CONSTRAINT product_address_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.product_order
    ADD CONSTRAINT product_order_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.realtime_service_address
    ADD CONSTRAINT realtime_service_address_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.realtime_service_category
    ADD CONSTRAINT realtime_service_category_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.realtime_service_image
    ADD CONSTRAINT realtime_service_image_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.realtime_service
    ADD CONSTRAINT realtime_service_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.realtime_service_rate
    ADD CONSTRAINT realtime_service_rate_pkey PRIMARY KEY (user_id, service_id);
ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (name);
ALTER TABLE ONLY public.service_discount
    ADD CONSTRAINT service_discount_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.shipping_address
    ADD CONSTRAINT shipping_address_pkey PRIMARY KEY ("orderID");
ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT shopping_cart_pkey PRIMARY KEY ("productID", "userID");
ALTER TABLE ONLY public.supplier_address
    ADD CONSTRAINT supplier_address_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.supplier_status
    ADD CONSTRAINT supplier_status_pkey PRIMARY KEY (value);
ALTER TABLE ONLY public.supplier_varified_by
    ADD CONSTRAINT supplier_varified_by_pkey PRIMARY KEY ("userID", "supplierID");
ALTER TABLE ONLY public.users
    ADD CONSTRAINT user_email_key UNIQUE (email);
ALTER TABLE ONLY public.user_physical_product_history
    ADD CONSTRAINT user_physical_product_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.users
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.user_realtime_service_history
    ADD CONSTRAINT user_realtime_service_history_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.virtual_service_address
    ADD CONSTRAINT virtual_service_address_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.virtual_service_category
    ADD CONSTRAINT virtual_service_category_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.virtual_service_image
    ADD CONSTRAINT virtual_service_image_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.virtual_service
    ADD CONSTRAINT virtual_service_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.virtual_service_rate
    ADD CONSTRAINT virtual_service_rate_pkey PRIMARY KEY (user_id, service_id);
CREATE OR REPLACE VIEW public.new_release_realtime_product AS
 SELECT product.title,
    product.id,
    product.cover_image,
    product.description,
    product.category_id,
    product.sub_category_id,
    avg(rate.rating) AS average_rate,
    product.amount,
    product.unit_price,
    product.created_at,
    product.updated_at,
    product.status,
    product.discount_id
   FROM (public.physical_product product
     LEFT JOIN public.physical_product_rate rate ON ((product.id = rate.product_id)))
  WHERE (product.created_at >= (now() - '3 days'::interval))
  GROUP BY product.id;
CREATE OR REPLACE VIEW public.new_release_digital_product AS
 SELECT product.title,
    product.id,
    product.cover_image,
    product.description,
    product.category_id,
    avg(rate.rate) AS average_rate,
    product.unit_price,
    product.created_at,
    product.updated_at
   FROM (public.digital_product product
     LEFT JOIN public.digital_product_rate rate ON ((product.id = rate.product_id)))
  WHERE (product.created_at >= (now() - '3 days'::interval))
  GROUP BY product.id;
CREATE TRIGGER set_public_physical_product_updated_at BEFORE UPDATE ON public.physical_product FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_physical_product_updated_at ON public.physical_product IS 'trigger to set value of column "updated_at" to current timestamp on row update';
CREATE TRIGGER set_public_virtual_service_updated_at BEFORE UPDATE ON public.virtual_service FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMENT ON TRIGGER set_public_virtual_service_updated_at ON public.virtual_service IS 'trigger to set value of column "updated_at" to current timestamp on row update';
ALTER TABLE ONLY public.digital_product
    ADD CONSTRAINT "digital_product_categoryID_fkey" FOREIGN KEY (category_id) REFERENCES public.digital_product_category(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.digital_product
    ADD CONSTRAINT "digital_product_discountID_fkey" FOREIGN KEY (discount_id) REFERENCES public.product_discount(id) ON UPDATE RESTRICT ON DELETE SET NULL;
ALTER TABLE ONLY public.digital_product_image
    ADD CONSTRAINT "digital_product_image_productID_fkey" FOREIGN KEY ("productID") REFERENCES public.digital_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.digital_product_rate
    ADD CONSTRAINT "digital_product_rate_productID_fkey" FOREIGN KEY (product_id) REFERENCES public.digital_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.digital_product_rate
    ADD CONSTRAINT "digital_product_rate_userID_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.digital_product
    ADD CONSTRAINT "digital_product_supplierID_fkey" FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.order_detail
    ADD CONSTRAINT "order_detail_orderID_fkey" FOREIGN KEY ("orderID") REFERENCES public.product_order(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.order_detail
    ADD CONSTRAINT "order_detail_productID_fkey" FOREIGN KEY ("productID") REFERENCES public.physical_product(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT "physical_product_categoryID_fkey" FOREIGN KEY (category_id) REFERENCES public.physical_product_category(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT "physical_product_discountID_fkey" FOREIGN KEY (discount_id) REFERENCES public.product_discount(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product_image
    ADD CONSTRAINT physical_product_image_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.physical_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.physical_product_rate
    ADD CONSTRAINT "physical_product_rate_productID_fkey" FOREIGN KEY (product_id) REFERENCES public.physical_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.physical_product_rate
    ADD CONSTRAINT "physical_product_rate_userID_fkey" FOREIGN KEY ("user_Id") REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT physical_product_status_fkey FOREIGN KEY (status) REFERENCES public.product_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT "physical_product_subCategoryID_fkey" FOREIGN KEY (sub_category_id) REFERENCES public.physical_product_subcategory(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product_subcategory
    ADD CONSTRAINT "physical_product_subcategory_categoryID_fkey" FOREIGN KEY (category_id) REFERENCES public.physical_product_category(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.physical_product
    ADD CONSTRAINT "physical_product_supplierID_fkey" FOREIGN KEY (supplier_id) REFERENCES public.supplier(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.product_address
    ADD CONSTRAINT product_address_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.physical_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.product_order
    ADD CONSTRAINT "product_order_customerID_fkey" FOREIGN KEY ("customerID") REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.product_order
    ADD CONSTRAINT product_order_status_fkey FOREIGN KEY (status) REFERENCES public.order_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.realtime_service
    ADD CONSTRAINT "realtime_service_accountID_fkey" FOREIGN KEY ("accountID") REFERENCES public.account(id) ON UPDATE SET NULL ON DELETE SET NULL;
ALTER TABLE ONLY public.realtime_service_address
    ADD CONSTRAINT "realtime_service_address_serviceID_fkey" FOREIGN KEY ("serviceID") REFERENCES public.realtime_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.realtime_service
    ADD CONSTRAINT "realtime_service_categoryID_fkey" FOREIGN KEY (category_id) REFERENCES public.realtime_service_category(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.realtime_service
    ADD CONSTRAINT realtime_service_discount_fkey FOREIGN KEY (discount_id) REFERENCES public.service_discount(id) ON UPDATE SET NULL ON DELETE SET NULL;
ALTER TABLE ONLY public.realtime_service_image
    ADD CONSTRAINT "realtime_service_image_serviceID_fkey" FOREIGN KEY ("serviceID") REFERENCES public.realtime_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.realtime_service_rate
    ADD CONSTRAINT "realtime_service_rate_serviceID_fkey" FOREIGN KEY (service_id) REFERENCES public.realtime_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.realtime_service_rate
    ADD CONSTRAINT "realtime_service_rate_userID_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.realtime_service
    ADD CONSTRAINT realtime_service_service_owner_fkey FOREIGN KEY (service_owner) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.shipping_address
    ADD CONSTRAINT "shipping_address_orderID_fkey" FOREIGN KEY ("orderID") REFERENCES public.product_order(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT "shopping_cart_productID_fkey" FOREIGN KEY ("productID") REFERENCES public.physical_product(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.shopping_cart
    ADD CONSTRAINT "shopping_cart_userID_fkey" FOREIGN KEY ("userID") REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.supplier_address
    ADD CONSTRAINT "supplier_address_supplierID_fkey" FOREIGN KEY ("supplierID") REFERENCES public.supplier(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_id_fkey FOREIGN KEY (id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.supplier_varified_by
    ADD CONSTRAINT supplier_varified_by_status_fkey FOREIGN KEY (status) REFERENCES public.supplier_status(value) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.supplier_varified_by
    ADD CONSTRAINT "supplier_varified_by_supplierID_fkey" FOREIGN KEY ("supplierID") REFERENCES public.supplier(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.supplier_varified_by
    ADD CONSTRAINT "supplier_varified_by_userID_fkey" FOREIGN KEY ("userID") REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT user_role_fkey FOREIGN KEY (role) REFERENCES public.role(name) ON UPDATE CASCADE;
ALTER TABLE ONLY public.virtual_service
    ADD CONSTRAINT virtual_service_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.account(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.virtual_service_address
    ADD CONSTRAINT virtual_service_address_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.virtual_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.virtual_service
    ADD CONSTRAINT "virtual_service_categoryID_fkey" FOREIGN KEY (category_id) REFERENCES public.virtual_service_category(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
ALTER TABLE ONLY public.virtual_service
    ADD CONSTRAINT virtual_service_discount_id_fkey FOREIGN KEY (discount_id) REFERENCES public.service_discount(id) ON UPDATE RESTRICT ON DELETE SET NULL;
ALTER TABLE ONLY public.virtual_service_image
    ADD CONSTRAINT virtual_service_image_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.virtual_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.virtual_service_rate
    ADD CONSTRAINT virtual_service_rate_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.virtual_service(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.virtual_service_rate
    ADD CONSTRAINT virtual_service_rate_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE CASCADE;
ALTER TABLE ONLY public.virtual_service
    ADD CONSTRAINT virtual_service_service_owner_fkey FOREIGN KEY (service_owner) REFERENCES public.users(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
