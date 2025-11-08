


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE SCHEMA IF NOT EXISTS "sagas";


ALTER SCHEMA "sagas" OWNER TO "postgres";


CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";





SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."organisations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."organisations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "client" "text",
    "status" "text" DEFAULT 'draft'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."suppliers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text",
    "name" "text",
    "currency" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."suppliers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."work_sites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid",
    "name" "text" NOT NULL,
    "address" "text",
    "status" "text" DEFAULT 'active'::"text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."work_sites" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."material_categories" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "parent_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "sagas"."material_categories" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."material_estimate_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "estimate_id" "uuid" NOT NULL,
    "line_no" integer DEFAULT 1 NOT NULL,
    "material_code" "text",
    "description" "text" NOT NULL,
    "qty" numeric(18,3) DEFAULT 0 NOT NULL,
    "unit" "text" DEFAULT 'pcs'::"text" NOT NULL,
    "unit_price" numeric(18,2) DEFAULT 0 NOT NULL,
    "amount" numeric(18,2) GENERATED ALWAYS AS (("qty" * "unit_price")) STORED,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "sagas"."material_estimate_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."material_estimates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "work_site_id" "uuid",
    "code" "text",
    "title" "text" NOT NULL,
    "currency" "text" DEFAULT 'AUD'::"text" NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "supplier" "text",
    "notes" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "material_estimates_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'issued'::"text", 'approved'::"text", 'archived'::"text"])))
);


ALTER TABLE "sagas"."material_estimates" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."materials_catalog" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "supplier_id" "uuid",
    "supplier_code" "text",
    "name" "text" NOT NULL,
    "category_id" "uuid",
    "unit" "text",
    "pack_size" "text",
    "currency" "text" DEFAULT 'AUD'::"text",
    "base_price" numeric(18,2),
    "effective_date" "date",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    CONSTRAINT "materials_catalog_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'inactive'::"text"])))
);


ALTER TABLE "sagas"."materials_catalog" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."memberships" (
    "org_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    CONSTRAINT "memberships_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text", 'viewer'::"text"])))
);


ALTER TABLE "sagas"."memberships" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."organisations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "sagas"."organisations" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."price_list_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "price_list_id" "uuid" NOT NULL,
    "supplier_code" "text",
    "description" "text",
    "unit" "text",
    "pack_size" "text",
    "list_price" numeric(18,2),
    "discount_pct" numeric(5,2) DEFAULT 0,
    "net_price" numeric(18,2) GENERATED ALWAYS AS (("list_price" * ((1)::numeric - (COALESCE("discount_pct", (0)::numeric) / (100)::numeric)))) STORED,
    "source_meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "sagas"."price_list_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."price_lists" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "supplier_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "valid_from" "date",
    "valid_to" "date",
    "currency" "text" DEFAULT 'AUD'::"text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "sagas"."price_lists" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."projects" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "client" "text"
);


ALTER TABLE "sagas"."projects" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."site_contractors" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "work_site_id" "uuid" NOT NULL,
    "company" "text",
    "role" "text",
    "contact_name" "text",
    "contact_phone" "text",
    "contact_email" "text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "sagas"."site_contractors" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."staging_raw_prices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "supplier_id" "uuid",
    "source_filename" "text",
    "row_no" integer,
    "row_data" "jsonb" NOT NULL,
    "imported_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "processed" boolean DEFAULT false NOT NULL,
    "process_notes" "text",
    "row_hash" "text"
);


ALTER TABLE "sagas"."staging_raw_prices" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."suppliers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "org_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "code" "text",
    "currency" "text" DEFAULT 'AUD'::"text",
    "notes" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "sagas"."suppliers" OWNER TO "postgres";


CREATE OR REPLACE VIEW "sagas"."v_material_estimate_totals" AS
 SELECT "me"."id" AS "estimate_id",
    ("sum"("mei"."amount"))::numeric(18,2) AS "total_amount"
   FROM ("sagas"."material_estimate_items" "mei"
     JOIN "sagas"."material_estimates" "me" ON (("me"."id" = "mei"."estimate_id")))
  GROUP BY "me"."id";


ALTER VIEW "sagas"."v_material_estimate_totals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."work_estimate_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "estimate_id" "uuid" NOT NULL,
    "line_no" integer DEFAULT 1 NOT NULL,
    "description" "text" NOT NULL,
    "trade" "text",
    "qty" numeric(18,3) DEFAULT 0 NOT NULL,
    "unit" "text" DEFAULT 'm2'::"text" NOT NULL,
    "rate" numeric(18,2) DEFAULT 0 NOT NULL,
    "amount" numeric(18,2) GENERATED ALWAYS AS (("qty" * "rate")) STORED,
    "meta" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL
);


ALTER TABLE "sagas"."work_estimate_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."work_estimates" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "work_site_id" "uuid",
    "code" "text",
    "title" "text" NOT NULL,
    "currency" "text" DEFAULT 'AUD'::"text" NOT NULL,
    "status" "text" DEFAULT 'draft'::"text" NOT NULL,
    "notes" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "work_estimates_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'issued'::"text", 'approved'::"text", 'archived'::"text"])))
);


ALTER TABLE "sagas"."work_estimates" OWNER TO "postgres";


CREATE OR REPLACE VIEW "sagas"."v_work_estimate_totals" AS
 SELECT "we"."id" AS "estimate_id",
    ("sum"("wei"."amount"))::numeric(18,2) AS "total_amount"
   FROM ("sagas"."work_estimate_items" "wei"
     JOIN "sagas"."work_estimates" "we" ON (("we"."id" = "wei"."estimate_id")))
  GROUP BY "we"."id";


ALTER VIEW "sagas"."v_work_estimate_totals" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "sagas"."work_sites" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "project_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "address" "text",
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "notes" "text",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "work_sites_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'closed'::"text", 'archived'::"text"])))
);


ALTER TABLE "sagas"."work_sites" OWNER TO "postgres";


ALTER TABLE ONLY "public"."organisations"
    ADD CONSTRAINT "organisations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."work_sites"
    ADD CONSTRAINT "work_sites_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."material_categories"
    ADD CONSTRAINT "material_categories_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."material_estimate_items"
    ADD CONSTRAINT "material_estimate_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."material_estimates"
    ADD CONSTRAINT "material_estimates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."materials_catalog"
    ADD CONSTRAINT "materials_catalog_org_id_supplier_id_supplier_code_key" UNIQUE ("org_id", "supplier_id", "supplier_code");



ALTER TABLE ONLY "sagas"."materials_catalog"
    ADD CONSTRAINT "materials_catalog_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."memberships"
    ADD CONSTRAINT "memberships_pkey" PRIMARY KEY ("org_id", "user_id");



ALTER TABLE ONLY "sagas"."organisations"
    ADD CONSTRAINT "organisations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."price_list_items"
    ADD CONSTRAINT "price_list_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."price_lists"
    ADD CONSTRAINT "price_lists_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."projects"
    ADD CONSTRAINT "projects_code_key" UNIQUE ("code");



ALTER TABLE ONLY "sagas"."projects"
    ADD CONSTRAINT "projects_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."site_contractors"
    ADD CONSTRAINT "site_contractors_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."staging_raw_prices"
    ADD CONSTRAINT "staging_raw_prices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."suppliers"
    ADD CONSTRAINT "suppliers_code_key" UNIQUE ("code");



ALTER TABLE ONLY "sagas"."suppliers"
    ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."work_estimate_items"
    ADD CONSTRAINT "work_estimate_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."work_estimates"
    ADD CONSTRAINT "work_estimates_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "sagas"."work_sites"
    ADD CONSTRAINT "work_sites_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_matcat_org" ON "sagas"."material_categories" USING "btree" ("org_id");



CREATE INDEX "idx_matcat_supplier" ON "sagas"."materials_catalog" USING "btree" ("supplier_id");



CREATE INDEX "idx_material_estimate_items_est" ON "sagas"."material_estimate_items" USING "btree" ("estimate_id");



CREATE INDEX "idx_material_estimates_project" ON "sagas"."material_estimates" USING "btree" ("project_id");



CREATE INDEX "idx_pl_org" ON "sagas"."price_lists" USING "btree" ("org_id");



CREATE INDEX "idx_pli_pl" ON "sagas"."price_list_items" USING "btree" ("price_list_id");



CREATE INDEX "idx_projects_created" ON "sagas"."projects" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_projects_created_at" ON "sagas"."projects" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_projects_org_id" ON "sagas"."projects" USING "btree" ("org_id");



CREATE INDEX "idx_projects_status" ON "sagas"."projects" USING "btree" ("status");



CREATE INDEX "idx_site_contractor_site" ON "sagas"."site_contractors" USING "btree" ("work_site_id");



CREATE INDEX "idx_staging_org" ON "sagas"."staging_raw_prices" USING "btree" ("org_id");



CREATE INDEX "idx_suppliers_org" ON "sagas"."suppliers" USING "btree" ("org_id");



CREATE INDEX "idx_work_estimate_items_est" ON "sagas"."work_estimate_items" USING "btree" ("estimate_id");



CREATE INDEX "idx_work_estimates_project" ON "sagas"."work_estimates" USING "btree" ("project_id");



CREATE INDEX "idx_work_sites_project" ON "sagas"."work_sites" USING "btree" ("project_id");



CREATE UNIQUE INDEX "uq_staging_unique" ON "sagas"."staging_raw_prices" USING "btree" ("org_id", "supplier_id", "source_filename", "row_hash");



ALTER TABLE ONLY "public"."work_sites"
    ADD CONSTRAINT "work_sites_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."material_categories"
    ADD CONSTRAINT "material_categories_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."material_categories"
    ADD CONSTRAINT "material_categories_parent_id_fkey" FOREIGN KEY ("parent_id") REFERENCES "sagas"."material_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."material_estimate_items"
    ADD CONSTRAINT "material_estimate_items_estimate_id_fkey" FOREIGN KEY ("estimate_id") REFERENCES "sagas"."material_estimates"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."material_estimates"
    ADD CONSTRAINT "material_estimates_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "sagas"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."material_estimates"
    ADD CONSTRAINT "material_estimates_work_site_id_fkey" FOREIGN KEY ("work_site_id") REFERENCES "sagas"."work_sites"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."materials_catalog"
    ADD CONSTRAINT "materials_catalog_category_id_fkey" FOREIGN KEY ("category_id") REFERENCES "sagas"."material_categories"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."materials_catalog"
    ADD CONSTRAINT "materials_catalog_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."materials_catalog"
    ADD CONSTRAINT "materials_catalog_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "sagas"."suppliers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."memberships"
    ADD CONSTRAINT "memberships_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."price_list_items"
    ADD CONSTRAINT "price_list_items_price_list_id_fkey" FOREIGN KEY ("price_list_id") REFERENCES "sagas"."price_lists"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."price_lists"
    ADD CONSTRAINT "price_lists_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."price_lists"
    ADD CONSTRAINT "price_lists_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "sagas"."suppliers"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."projects"
    ADD CONSTRAINT "projects_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."site_contractors"
    ADD CONSTRAINT "site_contractors_work_site_id_fkey" FOREIGN KEY ("work_site_id") REFERENCES "sagas"."work_sites"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."staging_raw_prices"
    ADD CONSTRAINT "staging_raw_prices_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."staging_raw_prices"
    ADD CONSTRAINT "staging_raw_prices_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "sagas"."suppliers"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."suppliers"
    ADD CONSTRAINT "suppliers_org_id_fkey" FOREIGN KEY ("org_id") REFERENCES "sagas"."organisations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."work_estimate_items"
    ADD CONSTRAINT "work_estimate_items_estimate_id_fkey" FOREIGN KEY ("estimate_id") REFERENCES "sagas"."work_estimates"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."work_estimates"
    ADD CONSTRAINT "work_estimates_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "sagas"."projects"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "sagas"."work_estimates"
    ADD CONSTRAINT "work_estimates_work_site_id_fkey" FOREIGN KEY ("work_site_id") REFERENCES "sagas"."work_sites"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "sagas"."work_sites"
    ADD CONSTRAINT "work_sites_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "sagas"."projects"("id") ON DELETE CASCADE;



CREATE POLICY "proj_delete" ON "public"."projects" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "proj_insert" ON "public"."projects" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "proj_read" ON "public"."projects" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "proj_update" ON "public"."projects" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



ALTER TABLE "public"."projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "anon can insert projects" ON "sagas"."projects" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "anon can read projects" ON "sagas"."projects" FOR SELECT TO "anon" USING (true);



CREATE POLICY "anon_can_read_projects" ON "sagas"."projects" FOR SELECT USING (true);



CREATE POLICY "anon_can_select_projects" ON "sagas"."projects" FOR SELECT TO "anon" USING (true);



CREATE POLICY "auth_can_delete_projects" ON "sagas"."projects" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "auth_can_insert_projects" ON "sagas"."projects" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "auth_can_update_projects" ON "sagas"."projects" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "dev orgs all" ON "sagas"."organisations" USING (true) WITH CHECK (true);



CREATE POLICY "dev projects all" ON "sagas"."projects" USING (true) WITH CHECK (true);



CREATE POLICY "matcat_all" ON "sagas"."materials_catalog" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "materials_catalog"."org_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "materials_catalog"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



ALTER TABLE "sagas"."material_categories" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."material_estimate_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."material_estimates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."materials_catalog" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "mc_all" ON "sagas"."material_categories" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "material_categories"."org_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "material_categories"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "me_cud" ON "sagas"."material_estimates" USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "material_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "material_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "me_select" ON "sagas"."material_estimates" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "material_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"())))));



CREATE POLICY "mei_all" ON "sagas"."material_estimate_items" USING ((EXISTS ( SELECT 1
   FROM (("sagas"."material_estimates" "me"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "me"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("me"."id" = "material_estimate_items"."estimate_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("sagas"."material_estimates" "me"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "me"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("me"."id" = "material_estimate_items"."estimate_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "memb_delete_self" ON "sagas"."memberships" FOR DELETE TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "memb_insert_self" ON "sagas"."memberships" FOR INSERT TO "authenticated" WITH CHECK (("user_id" = "auth"."uid"()));



CREATE POLICY "memb_select_self" ON "sagas"."memberships" FOR SELECT TO "authenticated" USING (("user_id" = "auth"."uid"()));



CREATE POLICY "memb_update_self" ON "sagas"."memberships" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));



ALTER TABLE "sagas"."memberships" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "org_delete" ON "sagas"."organisations" FOR DELETE USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "organisations"."id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = 'owner'::"text")))));



CREATE POLICY "org_insert" ON "sagas"."organisations" FOR INSERT WITH CHECK (("created_by" = "auth"."uid"()));



CREATE POLICY "org_select" ON "sagas"."organisations" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "organisations"."id") AND ("m"."user_id" = "auth"."uid"())))));



CREATE POLICY "org_update" ON "sagas"."organisations" FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "organisations"."id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text"]))))));



ALTER TABLE "sagas"."organisations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "pl_all" ON "sagas"."price_lists" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "price_lists"."org_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "price_lists"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "pli_all" ON "sagas"."price_list_items" USING ((EXISTS ( SELECT 1
   FROM ("sagas"."price_lists" "pl"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "pl"."org_id")))
  WHERE (("pl"."id" = "price_list_items"."price_list_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("sagas"."price_lists" "pl"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "pl"."org_id")))
  WHERE (("pl"."id" = "price_list_items"."price_list_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



ALTER TABLE "sagas"."price_list_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."price_lists" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "proj_cud" ON "sagas"."projects" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "projects"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "projects"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "proj_select" ON "sagas"."projects" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "projects"."org_id") AND ("m"."user_id" = "auth"."uid"())))));



ALTER TABLE "sagas"."projects" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "sc_all" ON "sagas"."site_contractors" USING ((EXISTS ( SELECT 1
   FROM (("sagas"."work_sites" "ws"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "ws"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("ws"."id" = "site_contractors"."work_site_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("sagas"."work_sites" "ws"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "ws"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("ws"."id" = "site_contractors"."work_site_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



ALTER TABLE "sagas"."site_contractors" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."staging_raw_prices" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "stg_all" ON "sagas"."staging_raw_prices" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "staging_raw_prices"."org_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "staging_raw_prices"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "sup_all" ON "sagas"."suppliers" USING ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "suppliers"."org_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM "sagas"."memberships" "m"
  WHERE (("m"."org_id" = "suppliers"."org_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



ALTER TABLE "sagas"."suppliers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "we_cud" ON "sagas"."work_estimates" USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "we_select" ON "sagas"."work_estimates" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_estimates"."project_id") AND ("m"."user_id" = "auth"."uid"())))));



CREATE POLICY "wei_all" ON "sagas"."work_estimate_items" USING ((EXISTS ( SELECT 1
   FROM (("sagas"."work_estimates" "we"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "we"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("we"."id" = "work_estimate_items"."estimate_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM (("sagas"."work_estimates" "we"
     JOIN "sagas"."projects" "p" ON (("p"."id" = "we"."project_id")))
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("we"."id" = "work_estimate_items"."estimate_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



ALTER TABLE "sagas"."work_estimate_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."work_estimates" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "sagas"."work_sites" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "ws_all" ON "sagas"."work_sites" USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_sites"."project_id") AND ("m"."user_id" = "auth"."uid"()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_sites"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "ws_cud" ON "sagas"."work_sites" USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_sites"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"])))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_sites"."project_id") AND ("m"."user_id" = "auth"."uid"()) AND ("m"."role" = ANY (ARRAY['owner'::"text", 'admin'::"text", 'member'::"text"]))))));



CREATE POLICY "ws_select" ON "sagas"."work_sites" FOR SELECT USING ((EXISTS ( SELECT 1
   FROM ("sagas"."projects" "p"
     JOIN "sagas"."memberships" "m" ON (("m"."org_id" = "p"."org_id")))
  WHERE (("p"."id" = "work_sites"."project_id") AND ("m"."user_id" = "auth"."uid"())))));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT USAGE ON SCHEMA "sagas" TO "anon";
GRANT USAGE ON SCHEMA "sagas" TO "authenticated";








































































































































































GRANT ALL ON TABLE "public"."organisations" TO "anon";
GRANT ALL ON TABLE "public"."organisations" TO "authenticated";
GRANT ALL ON TABLE "public"."organisations" TO "service_role";



GRANT ALL ON TABLE "public"."projects" TO "anon";
GRANT ALL ON TABLE "public"."projects" TO "authenticated";
GRANT ALL ON TABLE "public"."projects" TO "service_role";



GRANT ALL ON TABLE "public"."suppliers" TO "anon";
GRANT ALL ON TABLE "public"."suppliers" TO "authenticated";
GRANT ALL ON TABLE "public"."suppliers" TO "service_role";



GRANT ALL ON TABLE "public"."work_sites" TO "anon";
GRANT ALL ON TABLE "public"."work_sites" TO "authenticated";
GRANT ALL ON TABLE "public"."work_sites" TO "service_role";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_categories" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_categories" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_estimate_items" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_estimate_items" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_estimates" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."material_estimates" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."materials_catalog" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."materials_catalog" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."memberships" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."memberships" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."organisations" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."organisations" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."price_list_items" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."price_list_items" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."price_lists" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."price_lists" TO "authenticated";



GRANT ALL ON TABLE "sagas"."projects" TO "anon";
GRANT ALL ON TABLE "sagas"."projects" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."site_contractors" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."site_contractors" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."staging_raw_prices" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."staging_raw_prices" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."suppliers" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."suppliers" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."v_material_estimate_totals" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."v_material_estimate_totals" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_estimate_items" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_estimate_items" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_estimates" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_estimates" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."v_work_estimate_totals" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."v_work_estimate_totals" TO "authenticated";



GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_sites" TO "anon";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "sagas"."work_sites" TO "authenticated";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "sagas" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "sagas" GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO "authenticated";




























