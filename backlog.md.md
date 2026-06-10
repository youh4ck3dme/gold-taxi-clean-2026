# Backlog: Vývoj Bolt aplikácie vo Flutter

## 1. Analýza a definícia architektúry
### 1.1. Ciele aplikácie
- Vytvorenie mobilnej aplikácie pre správu a zobrazenie dát z WordPress JetEngine
- Responzívny dizajn pre rôzne zariadenia
- Offline režim s dátovou synchronizáciou
- Integrované SEO optimalizácie pre webové zobrazenie

### 1.2. Technologický stack
- **Frontend**: Flutter (Dart)
- **Backend**: WordPress + JetEngine (REST API / GraphQL)
- **Databáza**: WordPress DB (MySQL) + Firebase (pre offline dáta)
- **Stavové riadenie**: Riverpod / Bloc
- **Mapovanie dát**: JSON serializácia
- **Cache**: Hive / SharedPreferences
- **Analytics**: Firebase Analytics / Google Analytics

## 2. Databázová architektúra (WordPress JetEngine)
### 2.1. Hlavné entitné typy
- **Posts** (štandardné WordPress príspevky)
  - Polia: title, content, excerpt, featured_image, slug
  - SEO: Yoast SEO meta polia (title, description, focus_keyword)
  - Relations: author (User), categories (Taxonomy), tags (Taxonomy)

- **CPT (Custom Post Types)**
  - **Products**
    - Polia: price, stock, sku, categories (Taxonomy), attributes (CPT)
    - SEO: WooCommerce SEO polia
    - Relations: vendor (User), reviews (CPT)
  - **Services**
    - Polia: duration, price_range, service_provider (User)
    - SEO: špeciálne meta polia pre služby
  - **Events**
    - Polia: start_date, end_date, location, organizer (User)
    - Relations: event_categories (Taxonomy), event_tags (Taxonomy)

- **Taxonomies**
  - **Categories** (pre štandardné príspevky)
  - **Product Categories** (pre Products CPT)
  - **Service Categories** (pre Services CPT)
  - **Event Categories** (pre Events CPT)
  - **Tags** (univerzálne pre všetky CPT)

- **Users**
  - Polia: first_name, last_name, email, role, profile_picture
  - Relations: created_posts (Posts), created_products (Products), etc.
  - SEO: author archive stránky

- **Meta Fields** (JetEngine)
  - **Custom Fields** pre rozšírené dáta:
    - Products: discount, weight, dimensions
    - Services: availability, service_area
    - Events: capacity, registration_link

### 2.2. Vzťahy (Relations)
- **One-to-Many**
  - User → Posts (autor)
  - User → Products (predajca)
  - User → Services (poskytovateľ)
  - User → Events (organizátor)
  - Category → Posts (príspevky v kategórii)

- **Many-to-Many**
  - Post → Tags (štandardné WordPress)
  - Product → Product Attributes (rozšírené)
  - Event → Event Categories

- **Hierarchické**
  - Category → Subcategory (nested taxonomy)

## 3. Webová architektúra (WordPress + JetEngine)
### 3.1. Štruktúra stránok
- **Hlavné stránky**
  - Home (/) – Úvodná stránka s featured obsahom
  - Blog (/blog) – Zoznam príspevkov s filtrom
  - Products (/products) – Zoznam produktov s filtrom
  - Services (/services) – Zoznam služieb s filtrom
  - Events (/events) – Kalendár udalostí
  - About (/about) – Informácie o firme
  - Contact (/contact) – Kontakt form + mapa

- **Detailné stránky**
  - Post Detail (/blog/[slug]) – Detail príspevku
  - Product Detail (/products/[slug]) – Detail produktu
  - Service Detail (/services/[slug]) – Detail služby
  - Event Detail (/events/[slug]) – Detail udalosti
  - User Profile (/profile/[username]) – Profil používateľa

- **Archívne stránky**
  - Category Archive (/category/[slug]) – Príspevky v kategórii
  - Tag Archive (/tag/[slug]) – Príspevky s tagom
  - Author Archive (/author/[username]) – Príspevky autora

- **SEO optimalizované stránky**
  - Sitemap (/sitemap.xml) – Generovaná XML sitemapa
  - Robots.txt – Konfigurácia pre vyhľadávače
  - SEO Metadata – Yoast SEO integrované polia

### 3.2. API Endpointy (JetEngine)
- **Posts API**
  - GET /wp-json/jet-engine/v1/posts?per_page=10&page=1
  - GET /wp-json/jet-engine/v1/posts/{id}
  - GET /wp-json/jet-engine/v1/posts?category={slug}

- **Products API**
  - GET /wp-json/jet-engine/v1/products?per_page=10&page=1
  - GET /wp-json/jet-engine/v1/products/{id}
  - GET /wp-json/jet-engine/v1/products?category={slug}&price_min=10&price_max=100

- **Services API**
  - GET /wp-json/jet-engine/v1/services?per_page=10&page=1
  - GET /wp-json/jet-engine/v1/services/{id}

- **Events API**
  - GET /wp-json/jet-engine/v1/events?per_page=10&page=1
  - GET /wp-json/jet-engine/v1/events?date_from=2023-01-01&date_to=2023-12-31

- **Users API**
  - GET /wp-json/wp/v2/users/{id}
  - GET /wp-json/wp/v2/users?role=vendor

- **Search API**
  - GET /wp-json/jet-engine/v1/search?query={search_term}&type=post,product,service

## 4. Flutter Aplikácia
### 4.1. Štruktúra projektu
