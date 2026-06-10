 Vylepšený Blueprint: Vývoj Bolt aplikácie vo Flutter s WordPress JetEngine

## 1. Analýza a definícia architektúry
### 1.1. Ciele aplikácie
- Vytvorenie mobilnej aplikácie pre správu a zobrazenie dát z WordPress JetEngine
- Responzívny dizajn pre rôzne zariadenia (mobil, tablet, desktop)
- Offline režim s dátovou synchronizáciou (automatická a manuálna)
- Integrované SEO optimalizácie pre webové zobrazenie a deep linking
- Podpora viacjazyčnosti (i18n) pre globálne trhy
- Notifikácie o novinkách, udalostiach a zmenách v sledovaných položkách
- Integrovaný systém recenzií a hodnotení (pre produkty, služby, udalosti)
- Podpora viacerých platobných metód (ak sú relevantné pre daný typ webu)
- Podpora viacerých typov používateľov (customer, vendor, organizer, admin)
- Sledovanie používateľskej aktivity (história objednávok, rezervácií, hodnotení)
- Integrovaný systém sledovania položiek (follow) pre používateľov
- Podpora pre viacero typov lokalít (fyzické, online, hybridné)
- Integrovaný systém pre správu udalostí (jednorazové, opakujúce sa)
- Podpora pre viacero typov služieb (konzultácie, workshopy, dlhodobé služby)
- Integrovaný systém pre správu produktov (fyzické, digitálne, varianty)
- Podpora pre viacero typov obsahu (blog, články, správy, recenzie)

---

## 2. Databázová architektúra (WordPress JetEngine)
### 2.1. Hlavné entitné typy
#### **Posts (štandardné WordPress príspevky)**
- **Polia**:
  - `title`, `content`, `excerpt`, `featured_image`, `slug`
  - `post_status` (publish, draft, private, scheduled)
  - `comment_status` (open, closed)
  - `ping_status` (open, closed)
  - `menu_order` (pre poradie v menu)
  - `post_password` (pre chránené príspevky)
- **SEO polia** (Yoast SEO / Rank Math):
  - `seo_title`, `seo_description`, `focus_keyword`, `canonical_url`
  - `og_title`, `og_description`, `og_image`, `og_type`, `og_url`
  - `twitter_card`, `twitter_title`, `twitter_description`, `twitter_image`
  - `schema_markup` (JSON-LD pre štruktúrované dáta)
- **Relácie**:
  - `author` (User)
  - `categories` (Taxonomy)
  - `tags` (Taxonomy)
  - `post_meta` (JetEngine custom fields)
  - `related_posts` (Many-to-Many, JetEngine Relations)
  - `post_views` (počet zobrazení, JetEngine counter)
- **Meta polia** (JetEngine):
  - `custom_field_1`, `custom_field_2` (podľa potreby)
  - `featured_post` (boolean)
  - `post_template` (výber šablóny zobrazenia)
  - `post_visibility` (public, private, password protected)

#### **CPT (Custom Post Types)**
##### **Products**
- **Polia**:
  - `title`, `description`, `featured_image`, `gallery_images`
  - `price` (float), `regular_price` (float), `sale_price` (float)
  - `stock_quantity` (int), `low_stock_threshold` (int)
  - `sku` (unikatné), `manage_stock` (boolean)
  - `virtual` (boolean), `downloadable` (boolean)
  - `weight` (float, kg), `dimensions` (length, width, height)
  - `backorders` (no, notify, allow)
  - `purchase_note` (text)
  - `short_description` (krátky popis pre zoznamy)
  - `product_type` (simple, variable, grouped, external)
  - `tax_status` (taxable, shipping, none)
  - `sold_individually` (boolean)
- **SEO polia** (WooCommerce SEO):
  - `seo_title`, `seo_description`, `focus_keyword`
  - `og_title`, `og_description`, `og_image`, `og_type`
  - `twitter_card`, `twitter_title`, `twitter_description`, `twitter_image`
  - `schema_markup` (Product, Offer, AggregateRating)
- **Relácie**:
  - `author` (User)
  - `categories` (Product Category)
  - `tags` (Product Tag)
  - `attributes` (Product Attribute)
  - `reviews` (Review CPT)
  - `vendor` (User, pre multi-vendor)
  - `related_products` (Many-to-Many)
  - `upsell_products` (Many-to-Many)
  - `cross_sell_products` (Many-to-Many)
  - `product_galleries` (Media)
- **Meta polia** (JetEngine):
  - `discount_percentage` (float)
  - `featured_product` (boolean)
  - `custom_attributes` (JSON pre rozšírené vlastnosti)
  - `product_condition` (new, refurbished, used)
  - `warranty_period` (int, mesiace)
  - `shipping_class` (text)
  - `product_tags_custom` (JSON pre dodatočné tagy)

##### **Services**
- **Polia**:
  - `title`, `description`, `featured_image`
  - `duration` (int, minút/hodín/dní)
  - `price_range` (min_price, max_price)
  - `availability` (enum: available, limited, unavailable)
  - `service_area` (text, napr. "Bratislava a okolie")
  - `booking_link` (URL)
  - `contact_email`, `contact_phone`
  - `service_type` (enum: online, offline, hybrid)
  - `recurring` (boolean)
  - `recurrence_pattern` (weekly, biweekly, monthly, custom)
  - `recurrence_end_date` (datetime)
  - `capacity_per_session` (int)
  - `service_language` (text, napr. "Slovenčina, Angličtina")
- **SEO polia**:
  - `seo_title`, `seo_description`, `focus_keyword`
  - `og_title`, `og_description`, `og_image`, `og_type`
  - `twitter_card`, `twitter_title`, `twitter_description`, `twitter_image`
  - `schema_markup` (Service, Offer)
- **Relácie**:
  - `author` (User)
  - `categories` (Service Category)
  - `service_provider` (User)
  - `related_services` (Many-to-Many)
  - `service_attributes` (JetEngine custom fields)
  - `service_media` (Media)
  - `service_faq` (FAQ CPT)

##### **Events**
- **Polia**:
  - `title`, `description`, `featured_image`
  - `start_date` (datetime), `end_date` (datetime)
  - `location` (text + Google Maps coordinates)
  - `location_type` (enum: physical, online, hybrid)
  - `online_link` (URL, pre online udalosti)
  - `organizer` (User)
  - `capacity` (int), `registered_users` (int)
  - `registration_link` (URL)
  - `ticket_price` (float), `ticket_url` (URL)
  - `recurring` (boolean), `recurrence_pattern` (weekly, monthly, yearly)
  - `recurrence_end_date` (datetime)
  - `event_type` (enum: conference, workshop, webinar, social)
  - `tags_custom` (JSON pre dodatočné tagy)
- **SEO polia**:
  - `seo_title`, `seo_description`, `focus_keyword`
  - `og_title`, `og_description`, `og_image`, `og_type`
  - `twitter_card`, `twitter_title`, `twitter_description`, `twitter_image`
  - `schema_markup` (Event, Offer)
- **Relácie**:
  - `author` (User)
  - `event_categories` (Event Category)
  - `event_tags` (Tag)
  - `related_events` (Many-to-Many)
  - `sponsors` (User, Many-to-Many)
  - `event_media` (Media)
  - `event_speakers` (User, Many-to-Many)
  - `event_agenda` (Post, pre program udalosti)

#### **Taxonomies**
- **Univerzálne**:
  - `Categories` (pre štandardné príspevky)
  - `Tags` (pre všetky CPT)
- **Špecifické pre CPT**:
  - `Product Categories` (hierarchická, pre Products)
  - `Product Tags` (pre Products)
  - `Service Categories` (hierarchická, pre Services)
  - `Event Categories` (hierarchická, pre Events)
  - `Event Tags` (pre Events)
- **Ďalšie taxonomie** (podľa potreby):
  - `Location` (pre udalosti a služby, hierarchická)
  - `Price Range` (pre filtrovanie produktov)
  - `Product Condition` (new, refurbished, used)
  - `Service Type` (online, offline, hybrid)
  - `Event Type` (conference, workshop, webinar, social)
  - `Language` (pre viacjazyčné stránky)
  - `Age Group` (pre udalosti a služby)
  - `Difficulty Level` (pre workshopy a kurzy)

#### **Users**
- **Polia**:
  - `first_name`, `last_name`, `display_name`
  - `email`, `username`, `password`
  - `role` (subscriber, customer, vendor, organizer, admin)
  - `profile_picture` (URL)
  - `bio` (text)
  - `social_links` (JSON: facebook, instagram, linkedin, twitter)
  - `registration_date` (datetime)
  - `last_login` (datetime)
  - `account_status` (active, suspended, pending)
  - `billing_address` (JSON: street, city, country, postal_code)
  - `shipping_address` (JSON: street, city, country, postal_code)
  - `phone_number` (text)
  - `preferred_language` (text)
- **SEO polia** (pre author archive):
  - `seo_title`, `seo_description`
  - `og_title`, `og_description`, `og_image`
- **Relácie**:
  - `created_posts` (Posts)
  - `created_products` (Products)
  - `created_services` (Services)
  - `created_events` (Events)
  - `purchased_products` (Products, Many-to-Many)
  - `booked_services` (Services, Many-to-Many)
  - `attended_events` (Events, Many-to-Many)
  - `reviews` (Reviews)
  - `followed_posts` (Posts, Many-to-Many)
  - `followed_products` (Products, Many-to-Many)
  - `followed_services` (Services, Many-to-Many)
  - `followed_events` (Events, Many-to-Many)
- **Meta polia** (JetEngine):
  - `preferences` (JSON: notification_settings, language, theme)
  - `custom_fields` (podľa potreby)
  - `user_badges` (JSON: badge_type, badge_level)
  - `loyalty_points` (int)

#### **Reviews (Hodnotenia)**
- **Polia**:
  - `rating` (1-5, int)
  - `review_text` (text)
  - `review_date` (datetime)
  - `approved` (boolean)
  - `review_type` (enum: product, service, event, post)
  - `review_title` (text)
  - `pros` (text)
  - `cons` (text)
  - `recommend` (boolean)
- **Relácie**:
  - `reviewer` (User)
  - `reviewed_product` (Product)
  - `reviewed_service` (Service)
  - `reviewed_event` (Event)
  - `reviewed_post` (Post)

#### **FAQ (Často kladené otázky)**
- **Polia**:
  - `question` (text)
  - `answer` (text)
  - `faq_category` (Taxonomy)
  - `order` (int, pre poradie)
  - `is_featured` (boolean)
- **Relácie**:
  - `faq_category` (FAQ Category)
  - `related_faqs` (Many-to-Many)

#### **Orders (Objednávky)**
- **Polia**:
  - `order_number` (unikatné, text)
  - `order_date` (datetime)
  - `status` (enum: pending, processing, completed, cancelled, refunded)
  - `total_price` (float)
  - `tax_amount` (float)
  - `shipping_amount` (float)
  - `discount_amount` (float)
  - `payment_method` (text)
  - `payment_status` (enum: pending, paid, failed, refunded)
  - `billing_address` (JSON)
  - `shipping_address` (JSON)
  - `customer_notes` (text)
  - `admin_notes` (text)
- **Relácie**:
  - `customer` (User)
  - `order_items` (Order Item, One-to-Many)
  - `order_meta` (JetEngine custom fields)

#### **Order Items (Položky objednávky)**
- **Polia**:
  - `product_id` (int)
  - `product_name` (text)
  - `product_price` (float)
  - `quantity` (int)
  - `total_price` (float)
  - `variation_id` (int, pre varianty produktov)
  - `variation_name` (text)
- **Relácie**:
  - `order` (Order)

#### **Bookings (Rezervácie)**
- **Polia**:
  - `booking_number` (unikatné, text)
  - `booking_date` (datetime)
  - `status` (enum: pending, confirmed, cancelled, completed)
  - `service_id` (int)
  - `service_name` (text)
  - `provider_id` (User)
  - `customer_id` (User)
  - `start_time` (datetime)
  - `end_time` (datetime)
  - `duration` (int, minút)
  - `price` (float)
  - `notes` (text)
  - `payment_status` (enum: pending, paid, failed)
- **Relácie**:
  - `service` (Service)
  - `provider` (User)
  - `customer` (User)
  - `booking_meta` (JetEngine custom fields)

#### **Notifications (Notifikácie)**
- **Polia**:
  - `title` (text)
  - `message` (text)
  - `type` (enum: general, order, booking, event, promotion)
  - `status` (enum: unread, read)
  - `sent_date` (datetime)
  - `read_date` (datetime)
  - `target_url` (URL, pre deep linking)
  - `is_priority` (boolean)
- **Relácie**:
  - `recipient` (User)
  - `related_entity` (Post/Product/Service/Event/Order)

#### **Media (Médiá)**
- **Polia**:
  - `title` (text)
  - `alt_text` (text, pre prístupnosť)
  - `caption` (text)
  - `description` (text)
  - `media_type` (enum: image, video, audio, document)
  - `mime_type` (text)
  - `file_url` (URL)
  - `file_size` (int, bytes)
  - `width` (int, px)
  - `height` (int, px)
  - `duration` (int, sekundy, pre video/audio)
- **Relácie**:
  - `uploaded_by` (User)
  - `attached_to` (Post/Product/Service/Event/User)

---

### 2.2. Vzťahy (Relations)
#### **One-to-Many**
- User → Posts (autor)
- User → Products (predajca/vlastník)
- User → Services (poskytovateľ)
- User → Events (organizátor)
- User → Reviews (hodnotiteľ)
- User → Orders (zákazník)
- User → Bookings (zákazník/poskytovateľ)
- User → Notifications (prijímateľ)
- Category → Posts (príspevky v kategórii)
- Category → Products (produkty v kategórii)
- Category → Services (služby v kategórii)
- Category → Events (udalosti v kategórii)
- Order → Order Items (položky objednávky)
- Service → Bookings (rezervácie)

#### **Many-to-Many**
- Post → Tags (štandardné WordPress)
- Product → Product Attributes (rozšírené)
- Product → Related Products
- Product → Upsell Products
- Product → Cross-sell Products
- Service → Related Services
- Event → Related Events
- Event → Sponsors (Users)
- Event → Speakers (Users)
- User → Purchased Products
- User → Booked Services
- User → Attended Events
- User → Followed Posts/Products/Services/Events
- User → Reviews (hodnotenia)
- User → Notifications (notifikácie)
- FAQ → Related FAQs
- Order → Order Meta (rozšírené dáta)

#### **Hierarchické**
- Category → Subcategory (nested taxonomy)
- Location → Sub-location (hierarchická)
- Event → Recurring Events (parent-child)
- Service → Service Categories (hierarchická)

---

## 3. Webová architektúra (WordPress + JetEngine)
### 3.1. Štruktúra stránok
#### **Hlavné stránky**
- **Home (/)**
  - Featured obsah (Products, Services, Events)
  - Sekcia "Novinky" (posledné príspevky)
  - Sekcia "Top produkty" (podľa predaja/hodnotenia)
  - Sekcia "Blížiace sa udalosti"
  - Sekcia "Najobľúbenejšie služby"
  - Call-to-action (napr. "Objednajte si službu", "Kúpte produkt")
  - Sekcia "Blog" (výber článkov)
  - Sekcia "Náš tím" (zoznam Userov s rolou organizer/vendor)
  - Sekcia "Často kladené otázky" (FAQ)
  - Sekcia "Recenzie" (výber najlepších recenzií)
  - Sekcia "Aktuálne akcie" (ak sú k dispozícii)

- **Blog (/blog)**
  - Zoznam príspevkov s filtrom (kategória, tag, autor)
  - Infinite scroll / paginácia
  - Vyhľadávanie
  - Sekcia "Najčítanejšie" (podľa zobrazení)
  - Sekcia "Najnovšie" (podľa dátumu)
  - Sekcia "Podľa autora"

- **Products (/products)**
  - Zoznam produktov s filtrom (kategória, cena, dostupnosť, značka, stav)
  - Zobrazenie grid/list
  - Infinite scroll / paginácia
  - Vyhľadávanie
  - Sekcia "Top produkty" (podľa predaja/hodnotenia)
  - Sekcia "Novinky" (nové produkty)
  - Sekcia "Akcie" (produkty so zľavou)

- **Product Detail (/products/[slug])**
  - Detail produktu s obrázkami, cenou, popisom
  - Sekcia "Ďalšie produkty" (related products)
  - Sekcia "Upsell produkty" (doporučené produkty)
  - Sekcia "Recenzie" (ak sú k dispozícii)
  - Tlačidlo "Pridať do košíka" (ak je e-shop)
  - Tlačidlo "Kontaktujte predajcu"
  - Sekcia "Často kladené otázky" (FAQ pre daný produkt)
  - Sekcia "Súvisiace produkty" (cross-sell)

- **Services (/services)**
  - Zoznam služieb s filtrom (kategória, dostupnosť, lokalita, typ)
  - Infinite scroll / paginácia
  - Vyhľadávanie
  - Sekcia "Top služby" (podľa hodnotenia)
  - Sekcia "Novinky" (nové služby)
  - Sekcia "Dostupné služby" (podľa dátumu)

- **Service Detail (/services/[slug])**
  - Detail služby s popisom, cenou, dostupnosťou
  - Sekcia "Ďalšie služby" (related services)
  - Tlačidlo "Rezervovať" (smeruje na booking_link alebo formulár)
  - Kontaktné informácie poskytovateľa
  - Sekcia "Často kladené otázky" (FAQ pre danú službu)
  - Sekcia "Recenzie" (ak sú k dispozícii)
  - Sekcia "Poskytovatelia" (ak je služba poskytovaná viacerými)

- **Events (/events)**
  - Kalendár udalostí (týždenný/mesačný/ročný pohľad)
  - Zoznam udalostí s filtrom (kategória, dátum, lokalita, typ)
  - Infinite scroll / paginácia
  - Vyhľadávanie
  - Sekcia "Blížiace sa udalosti"
  - Sekcia "Udalosti podľa kategórie"
  - Sekcia "Vyhľadávané udalosti"

- **Event Detail (/events/[slug])**
  - Detail udalosti s dátumom, lokalitou, popisom
  - Sekcia "Ďalšie udalosti" (related events)
  - Tlačidlo "Registrácia" (smeruje na registration_link)
  - Informácie o kapacite a registrovaných užívateľoch
  - Sekcia "Rečníci" (zoznam Userov s rolou speaker)
  - Sekcia "Program" (zoznam Postov s agendou)
  - Sekcia "Sponzori" (zoznam Userov s rolou sponsor)
  - Sekcia "Často kladené otázky" (FAQ pre danú udalosť)
  - Sekcia "Recenzie" (ak sú k dispozícii)

- **About (/about)**
  - Informácie o firme/ tíme
  - História, misia, hodnoty
  - Kontaktné informácie
  - Sekcia "Náš tím" (zoznam Userov s rolou organizer/vendor/speaker)
  - Sekcia "Partnerské firmy" (zoznam Userov s rolou partner)
  - Sekcia "Certifikáty a ocenenia"

- **Contact (/contact)**
  - Kontaktný formulár (meno, email, správa, predmet)
  - Mapa s lokalitou firmy (Google Maps)
  - Kontaktné informácie (email, telefón, sociálne siete)
  - Sekcia "Často kladené otázky" (FAQ)
  - Sekcia "Kontaktný formulár" (s možnosťou výberu typu dotazu)
  - Sekcia "Náš kontakt" (zoznam kontaktov podľa oddelení)

- **Profile (/profile/[username])**
  - Detail používateľa (meno, bio, profilová fotografia)
  - Zoznam vytvorených položiek (Posts, Products, Services, Events)
  - Sekcia "Moje objednávky" (ak je e-shop)
  - Sekcia "Moje rezervácie" (ak sú služby)
  - Sekcia "Moje udalosti" (ak sú registrované)
  - Sekcia "Moje recenzie" (ak sú k dispozícii)
  - Sekcia "Moje sledované položky" (follow)
  - Možnosť editácie profilu
  - Sekcia "Moje loyalty body" (ak je systém aktivovaný)

- **Search (/search)**
  - Full-text vyhľadávanie (Posts, Products, Services, Events, Users, FAQ)
  - Filtrovanie výsledkov (podľa typu obsahu, kategórie, dátumu)
  - Zobrazenie výsledkov v kategóriách
  - Autocomplete pre vyhľadávanie

- **Terms & Conditions (/terms)**
  - Podmienky používania
  - Podmienky pre nákup (ak je e-shop)
  - Podmienky pre rezerváciu (ak sú služby)
  - Podmienky pre registráciu na udalosti
  - Podmienky pre používateľský účet

- **Privacy Policy (/privacy)**
  - Ochrana osobných údajov (GDPR)
  - Zoznam spracovávaných údajov
  - Práva používateľov
  - Cookies politika

- **FAQ (/faq)**
  - Zoznam FAQ podľa kategórií
  - Vyhľadávanie v FAQ
  - Sekcia "Najčastejšie otázky"
  - Sekcia "Podľa kategórie"

- **Checkout (/checkout)**
  - Košík (ak je e-shop)
  - Formulár pre dokončenie objednávky
  - Výber platobnej metódy (karta, PayPal, bankový prevod, platba na mieste)
  - Potvrdenie objednávky
  - Zobrazenie sumára objednávky

- **Booking (/booking)**
  - Formulár pre rezerváciu služby
  - Výber dátumu a času
  - Výber poskytovateľa (ak je služba poskytovaná viacerými)
  - Zobrazenie dostupnosti
  - Potvrdenie rezervácie

#### **Archívne stránky**
- **Category Archive (/category/[slug])**
  - Zoznam položiek (Posts/Products/Services/Events) v danej kategórii
  - Filtrovanie a vyhľadávanie
  - Sekcia "Podkategórie"
  - Sekcia "Top položky" (podľa hodnotenia/predaja)

- **Tag Archive (/tag/[slug])**
  - Zoznam položiek s daným tagom
  - Sekcia "Súvisiace tagy"

- **Author Archive (/author/[username])**
  - Zoznam položiek vytvorených daným autorom
  - Informácie o autorovi (bio, profilová fotografia)
  - Sekcia "Ďalšie položky od autora"

#### **SEO optimalizované stránky**
- **Sitemap (/sitemap.xml)**
  - Generovaná XML sitemapa (všetky stránky, príspevky, produkty, služby, udalosti)
  - Podpora pre Google News sitemap (ak je relevantné)
  - Podpora pre image sitemap
  - Podpora pre video sitemap

- **Robots.txt**
  - Konfigurácia pre vyhľadávače (disallow/allow pravidlá)
  - Sitemap URL
  - Crawl-delay

- **SEO Metadata**
  - Yoast SEO / Rank Math integrované polia pre všetky stránky
  - Dynamické meta tagy pre detailné stránky
  - Automatické generovanie meta tagov pre archívne stránky
  - Podpora pre Open Graph a Twitter Cards

- **Open Graph / Social Sharing**
  - Automatické generovanie OG tagov pre sociálne siete
  - Možnosť manuálneho nastavenia pre konkrétne stránky
  - Generovanie OG tagov pre produkty, služby, udalosti
  - Generovanie OG tagov pre používateľské profily

#### **Ďalšie stránky (podľa potreby)**
- **Login (/login)**
  - Formulár pre prihlásenie (Email + heslo, Google, Apple, Facebook)
  - Odkaz na registráciu
  - Odkaz na obnovenie hesla
  - Sekcia "Zabudnuté heslo"

- **Register (/register)**
  - Formulár pre registráciu
  - Výber role (customer, vendor, organizer)
  - Podmienky používania (checkbox)
  - CAPTCHA (pre zamedzenie spamu)

- **Forgot Password (/forgot-password)**
  - Formulár pre obnovenie hesla
  - Odsielanie emailu s linkom na obnovenie

- **Reset Password (/reset-password?key=...&login=...)**
  - Formulár pre nastavenie nového hesla

- **My Account (/my-account)**
  - Prehľad používateľského účtu
  - Možnosť editácie profilu
  - Zoznam objednávok
  - Zoznam rezervácií
  - Zoznam sledovaných položiek
  - Možnosť odhlásenia

- **Wishlist (/wishlist)**
  - Zoznam obľúbených položiek používateľa
  - Možnosť pridania/odstránenia z obľúbených
  - Export/import wishlist

- **Compare (/compare)**
  - Porovnanie produktov (ak je e-shop)
  - Možnosť pridania/odstránenia produktov
  - Zobrazenie rozdielov medzi produktmi

- **Blog Category (/blog/category/[slug])**
  - Zoznam príspevkov v danej kategórii blogu

- **Blog Tag (/blog/tag/[slug])**
  - Zoznam príspevkov s daným tagom

- **Product Category (/products/category/[slug])**
  - Zoznam produktov v danej kategórii

- **Product Tag (/products/tag/[slug])**
  - Zoznam produktov s daným tagom

- **Service Category (/services/category/[slug])**
  - Zoznam služieb v danej kategórii

- **Event Category (/events/category/[slug])**
  - Zoznam udalostí v danej kategórii

- **Location Archive (/location/[slug])**
  - Zoznam udalostí/služieb v danej lokalite
  - Hierarchické zobrazenie lokalít

- **404 (/404)**
  - Stránka pre neexistujúce URL
  - Sekcia "Najčastejšie navštevované stránky"
  - Vyhľadávanie

- **Maintenance (/maintenance)**
  - Stránka pre údržbu webu (ak je potrebné)
  - ETA do obnovenia

---

### 3.2. API Endpointy (JetEngine + WP REST API)
#### **Posts API**
- `GET /wp-json/wp/v2/posts?per_page=10&page=1&_embed&_fields=id,title,excerpt,featured_media,date,categories,tags,author`
- `GET /wp-json/wp/v2/posts/{id}?_embed&_fields=id,title,content,excerpt,featured_media,date,categories,tags,author,meta`
- `GET /wp-json/wp/v2/posts?category={slug}&tags={tag_slug}&_embed`
- `GET /wp-json/wp/v2/posts?search={query}&_fields=id,title,excerpt,featured_media`
- `GET /wp-json/wp/v2/posts?author={user_id}&_fields=id,title,date`
- `GET /wp-json/wp/v2/posts?date_from=2023-01-01&date_to=2023-12-31&_fields=id,title,date`

#### **Products API (WooCommerce + JetEngine)**
- `GET /wp-json/wc/v3/products?per_page=10&page=1&_embed&_fields=id,name,price,images,stock_status,attributes,categories,tags`
- `GET /wp-json/wc/v3/products/{id}?_embed&_fields=id,name,description,price,regular_price,sale_price,images,stock_status,attributes,categories,tags,meta`
- `GET /wp-json/wc/v3/products?category={slug}&stock_status=instock&price_min=10&price_max=100&_fields=id,name,price,images,stock_status`
- `GET /wp-json/wc/v3/products?search={query}&_fields=id,name,price,images,stock_status`
- `GET /wp-json/wc/v3/products?attribute={attribute_slug}&attribute_term={term_slug}&_fields=id,name,price,images`
- `GET /wp-json/jetelementor/v1/relations/products?related_to={post_id}&_fields=id,name,price,images`
- `GET /wp-json/wc/v3/products?featured=true&per_page=5&_fields=id,name,price,images`
- `GET /wp-json/wc/v3/products?on_sale=true&per_page=5&_fields=id,name,price,images`

#### **Services API (JetEngine)**
- `GET /wp-json/jetelementor/v1/services?per_page=10&page=1&_fields=id,title,description,featured_image,price_range,availability,service_area,categories,tags`
- `GET /wp-json/jetelementor/v1/services/{id}?_fields=id,title,description,featured_image,price_range,availability,service_area,categories,tags,meta`
- `GET /wp-json/jetelementor/v1/services?category={slug}&availability=available&_fields=id,title,description,featured_image,price_range`
- `GET /wp-json/jetelementor/v1/services?search={query}&_fields=id,title,description,featured_image`
- `GET /wp-json/jetelementor/v1/services?service_provider={user_id}&_fields=id,title,description,featured_image`
- `GET /wp-json/jetelementor/v1/services?service_type=online&_fields=id,title,description,featured_image`

#### **Events API (JetEngine)**
- `GET /wp-json/jetelementor/v1/events?per_page=10&page=1&_fields=id,title,start_date,end_date,featured_image,location,capacity,categories,tags`
- `GET /wp-json/jetelementor/v1/events/{id}?_fields=id,title,description,start_date,end_date,featured_image,location,capacity,registration_link,ticket_price,categories,tags,meta`
- `GET /wp-json/jetelementor/v1/events?date_from=2023-01-01&date_to=2023-12-31&category={slug}&_fields=id,title,start_date,end_date,featured_image`
- `GET /wp-json/jetelementor/v1/events?search={query}&_fields=id,title,start_date,end_date,featured_image`
- `GET /wp-json/jetelementor/v1/events?organizer={user_id}&_fields=id,title,start_date,end_date,featured_image`
- `GET /wp-json/jetelementor/v1/events?location={location_slug}&_fields=id,title,start_date,end_date,featured_image`

#### **Users API**
- `GET /wp-json/wp/v2/users/{id}?_fields=id,display_name,avatar_urls,roles,meta`
- `GET /wp-json/wp/v2/users?role=vendor&per_page=10&_fields=id,display_name,avatar_urls`
- `GET /wp-json/wp/v2/users?search={query}&_fields=id,display_name,avatar_urls`
- `GET /wp-json/wp/v2/users?role=organizer&per_page=10&_fields=id,display_name,avatar_urls`
- `GET /wp-json/jetelementor/v1/users/{id}/profile?include=bio,social_links,preferences`

#### **Reviews API**
- `GET /wp-json/jetelementor/v1/reviews?per_page=10&page=1&product={product_id}&_fields=id,rating,review_text,reviewer,review_date`
- `GET /wp-json/jetelementor/v1/reviews/{id}?_fields=id,rating,review_text,reviewer,review_date,reviewed_product,reviewed_service,reviewed_event`
- `GET /wp-json/jetelementor/v1/reviews?reviewer={user_id}&_fields=id,rating,review_text,review_date,reviewed_product,reviewed_service`
- `GET /wp-json/jetelementor/v1/reviews?reviewed_product={product_id}&approved=true&_fields=id,rating,review_text,reviewer,review_date`

#### **Orders API (WooCommerce)**
- `GET /wp-json/wc/v3/orders?per_page=10&page=1&customer={user_id}&_fields=id,number,date,status,total,line_items`
- `GET /wp-json/wc/v3/orders/{id}?_fields=id,number,date,status,total,line_items,billing,shipping,payment_method`
- `GET /wp-json/wc/v3/orders?status=completed&per_page=5&_fields=id,number,date,total`
- `GET /wp-json/wc/v3/orders?customer={user_id}&status=processing&_fields=id,number,date,total`

#### **Bookings API (JetEngine)**
- `GET /wp-json/jetelementor/v1/bookings?per_page=10&page=1&customer={user_id}&_fields=id,booking_number,booking_date,status,service,provider,start_time,end_time,price`
- `GET /wp-json/jetelementor/v1/bookings/{id}?_fields=id,booking_number,booking_date,status,service,provider,customer,start_time,end_time,price,notes`
- `GET /wp-json/jetelementor/v1/bookings?provider={user_id}&status=confirmed&_fields=id,booking_number,booking_date,service,customer,start_time,end_time`
- `GET /wp-json/jetelementor/v1/bookings?service={service_id}&status=confirmed&_fields=id,booking_number,booking_date,customer,start_time,end_time`

#### **FAQ API**
- `GET /wp-json/jetelementor/v1/faqs?per_page=10&page=1&category={slug}&_fields=id,question,answer,order`
- `GET /wp-json/jetelementor/v1/faqs/{id}?_fields=id,question,answer,category,order`
- `GET /wp-json/jetelementor/v1/faqs?search={query}&_fields=id,question,answer`

#### **Search API (JetEngine)**
- `GET /wp-json/jetelementor/v1/search?query={search_term}&type=post,product,service,event,user,faq&_fields=id,title,type,slug`

#### **Taxonomy API**
- `GET /wp-json/wp/v2/categories?type=product&_fields=id,name,slug`
- `GET /wp-json/wp/v2/tags?type=post&_fields=id,name,slug`
- `GET /wp-json/wp/v2/locations?parent=0&_fields=id,name,slug` (príklad pre hierarchickú taxonomiu)
- `GET /wp-json/wp/v2/price_ranges?per_page=20&_fields=id,name,slug`

#### **Media API**
- `GET /wp-json/wp/v2/media/{id}?_fields=id,source_url,alt_text,title`
- `GET /wp-json/wp/v2/media?parent={post_id}&_fields=id,source_url,alt_text`

#### **Custom Fields API (JetEngine)**
- `GET /wp-json/jetelementor/v1/meta/{post_type}/{id}?fields=custom_field_1,custom_field_2`
- `GET /wp-json/jetelementor/v1/meta/products/{id}?fields=discount_percentage,featured_product`
- `GET /wp-json/jetelementor/v1/meta/services/{id}?fields=availability,service_area`
- `GET /wp-json/jetelementor/v1/meta/events/{id}?fields=capacity,registration_link`

#### **Notifications API**
- `GET /wp-json/jetelementor/v1/notifications?recipient={user_id}&status=unread&_fields=id,title,message,type,sent_date,target_url`
- `GET /wp-json/jetelementor/v1/notifications/{id}?_fields=id,title,message,type,status,sent_date,read_date,target_url`

#### **User Activity API**
- `GET /wp-json/jetelementor/v1/user-activity?user_id={user_id}&type=order,booking,review&_fields=id,type,entity_id,entity_type,activity_date`
- `GET /wp-json/jetelementor/v1/user-favorites?user_id={user_id}&type=post,product,service,event&_fields=id,entity_id,entity_type`

---

## 4. Flutter Aplikácia
### 4.1. Štruktúra projektu
```text
lib/
├── core/
│   ├── constants/
│   │   ├── api_constants.dart       # API URL, endpointy, API keys
│   │   ├── app_constants.dart       # Aplikácia názov, verzia, farby, fonty
│   │   ├── firebase_constants.dart  # Firebase config
│   │   └── wordpres_constants.dart  # WordPress config (URL, API keys)
│   │
│   ├── utils/
│   │   ├── validators.dart          # Validácia formulárov (email, heslo, URL)
│   │   ├── formatters.dart          # Formátovanie dát (cena, dátum, percentá)
│   │   ├── helpers.dart             # Pomocné funkcie (odstranenie HTML tagov, zoznamovanie)
│   │   ├── extensions.dart          # Rozsirenia pre triedy (String, DateTime, num)
│   │   └── device_info.dart         # Získanie informácií o zariadení
│   │
│   ├── services/
│   │   ├── api_service.dart         # Hlavná služba pre API volania (REST/GraphQL)
│   │   ├── firebase_service.dart    # Firebase Authentication, Firestore, FCM
│   │   ├── cache_service.dart       # Cache (Hive, SharedPreferences, SQLite)
│   │   ├── notification_service.dart # Notifikácie (FCM, lokálne notifikácie)
│   │   ├── analytics_service.dart   # Analytics (Firebase, Google)
│   │   ├── deep_link_service.dart   # Deep linking (App Links, Universal Links)
│   │   ├── connectivity_service.dart # Sieťové pripojenie (offline/online)
│   │   └── location_service.dart    # Geolokačné služby (Google Maps, Mapbox)
│   │
│   └── widgets/
│       ├── buttons/                # Globálne tlačidlá (PrimaryButton, SecondaryButton)
│       ├── cards/                  # Globálne karty (ProductCard, EventCard, ServiceCard)
│       ├── dialogs/                # Globálne dialógy (ConfirmationDialog, ErrorDialog)
│       ├── fields/                 # Formulárové polia (TextField, Dropdown, DatePicker)
│       ├── loaders/                # Načítacie indikátory (ShimmerLoader, CircularLoader)
│       ├── shimmers/               # Shimmer loading efekty (pre zoznamy)
│       ├── bottom_sheets/          # Spodné panely (FilterBottomSheet, SortBottomSheet)
│       ├── app_bars/               # Hlavné a podrobné app bary
│       ├── navigation/             # Navigačné prvky (BottomNavBar, Drawer)
│       └── misc/                   # Ostatné widgety (RatingStars, PriceDisplay)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── local/
│   │   │   │   │   └── auth_local_datasource.dart # Lokálne uloženie auth dát
│   │   │   │   └── remote/
│   │   │   │       ├── auth_remote_datasource.dart # API volania pre auth
│   │   │   │       └── firebase_auth_datasource.dart # Firebase auth
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart                 # User model (DTO)
│   │   │   │   ├── auth_response_model.dart        # Auth response (token, user)
│   │   │   │   └── social_auth_model.dart          # Social auth response
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart            # Repozitár pre auth
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── login_page.dart
│   │   │   │   ├── register_page.dart
│   │   │   │   ├── forgot_password_page.dart
│   │   │   │   ├── reset_password_page.dart
│   │   │   │   └── social_auth_redirect_page.dart  # Pre social auth callback
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── login_form.dart
│   │   │   │   ├── register_form.dart
│   │   │   │   ├── social_auth_buttons.dart
│   │   │   │   └── auth_header.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── login_cubit.dart
│   │   │       ├── register_cubit.dart
│   │   │       └── auth_cubit.dart                 # Hlavný auth cubit
│   │   │
│   │   └── auth_injection.dart                     # Dependency injection
│   │
│   ├── home/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── home_remote_datasource.dart     # API volania pre home
│   │   │   │   └── home_local_datasource.dart      # Cache pre home
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── home_data_model.dart            # Dáta pre home stránku
│   │   │   │   └── featured_item_model.dart        # Featured položky
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── home_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── home_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── featured_section.dart
│   │   │   │   ├── new_items_section.dart
│   │   │   │   ├── top_products_section.dart
│   │   │   │   └── upcoming_events_section.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       └── home_cubit.dart
│   │   │
│   │   └── home_injection.dart
│   │
│   ├── blog/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── blog_remote_datasource.dart
│   │   │   │   └── blog_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── post_model.dart
│   │   │   │   ├── post_detail_model.dart
│   │   │   │   └── category_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── blog_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── blog_list_page.dart
│   │   │   │   └── blog_detail_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── post_card.dart
│   │   │   │   ├── post_list.dart
│   │   │   │   ├── category_filter.dart
│   │   │   │   └── search_bar.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── blog_list_cubit.dart
│   │   │       └── blog_detail_cubit.dart
│   │   │
│   │   └── blog_injection.dart
│   │
│   ├── products/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── products_remote_datasource.dart
│   │   │   │   └── products_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── product_model.dart
│   │   │   │   ├── product_detail_model.dart
│   │   │   │   ├── product_variation_model.dart
│   │   │   │   ├── category_model.dart
│   │   │   │   └── attribute_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── products_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── product_list_page.dart
│   │   │   │   ├── product_detail_page.dart
│   │   │   │   ├── product_search_page.dart
│   │   │   │   └── product_compare_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── product_card.dart
│   │   │   │   ├── product_grid.dart
│   │   │   │   ├── product_list.dart
│   │   │   │   ├── filter_bottom_sheet.dart
│   │   │   │   ├── sort_bottom_sheet.dart
│   │   │   │   ├── product_variation_selector.dart
│   │   │   │   └── wishlist_button.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── product_list_cubit.dart
│   │   │       ├── product_detail_cubit.dart
│   │   │       └── product_compare_cubit.dart
│   │   │
│   │   └── products_injection.dart
│   │
│   ├── services/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── services_remote_datasource.dart
│   │   │   │   └── services_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── service_model.dart
│   │   │   │   ├── service_detail_model.dart
│   │   │   │   ├── service_provider_model.dart
│   │   │   │   └── category_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── services_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── service_list_page.dart
│   │   │   │   ├── service_detail_page.dart
│   │   │   │   ├── service_search_page.dart
│   │   │   │   └── booking_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── service_card.dart
│   │   │   │   ├── service_list.dart
│   │   │   │   ├── service_filter.dart
│   │   │   │   ├── booking_form.dart
│   │   │   │   ├── provider_selector.dart
│   │   │   │   └── availability_calendar.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── service_list_cubit.dart
│   │   │       ├── service_detail_cubit.dart
│   │   │       └── booking_cubit.dart
│   │   │
│   │   └── services_injection.dart
│   │
│   ├── events/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── events_remote_datasource.dart
│   │   │   │   └── events_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── event_model.dart
│   │   │   │   ├── event_detail_model.dart
│   │   │   │   ├── event_speaker_model.dart
│   │   │   │   ├── event_sponsor_model.dart
│   │   │   │   └── category_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── events_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── event_list_page.dart
│   │   │   │   ├── event_detail_page.dart
│   │   │   │   ├── event_search_page.dart
│   │   │   │   ├── event_calendar_page.dart
│   │   │   │   └── event_registration_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── event_card.dart
│   │   │   │   ├── event_list.dart
│   │   │   │   ├── event_filter.dart
│   │   │   │   ├── event_calendar.dart
│   │   │   │   ├── speaker_card.dart
│   │   │   │   ├── sponsor_card.dart
│   │   │   │   └── registration_form.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── event_list_cubit.dart
│   │   │       ├── event_detail_cubit.dart
│   │   │       └── event_registration_cubit.dart
│   │   │
│   │   └── events_injection.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── profile_remote_datasource.dart
│   │   │   │   └── profile_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── profile_model.dart
│   │   │   │   ├── order_model.dart
│   │   │   │   ├── booking_model.dart
│   │   │   │   └── review_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── profile_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── profile_page.dart
│   │   │   │   ├── edit_profile_page.dart
│   │   │   │   ├── my_orders_page.dart
│   │   │   │   ├── my_bookings_page.dart
│   │   │   │   ├── my_events_page.dart
│   │   │   │   ├── my_reviews_page.dart
│   │   │   │   └── wishlist_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── profile_header.dart
│   │   │   │   ├── order_card.dart
│   │   │   │   ├── booking_card.dart
│   │   │   │   ├── review_card.dart
│   │   │   │   ├── wishlist_item.dart
│   │   │   │   └── loyalty_points_display.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── profile_cubit.dart
│   │   │       ├── edit_profile_cubit.dart
│   │   │       ├── my_orders_cubit.dart
│   │   │       └── my_bookings_cubit.dart
│   │   │
│   │   └── profile_injection.dart
│   │
│   ├── search/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── search_remote_datasource.dart
│   │   │   │   └── search_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── search_result_model.dart
│   │   │   │   └── search_history_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── search_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── search_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── search_bar.dart
│   │   │   │   ├── search_filters.dart
│   │   │   │   ├── search_results.dart
│   │   │   │   └── search_history.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       └── search_cubit.dart
│   │   │
│   │   └── search_injection.dart
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── checkout_remote_datasource.dart
│   │   │   │   └── checkout_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── cart_model.dart
│   │   │   │   ├── checkout_model.dart
│   │   │   │   ├── payment_method_model.dart
│   │   │   │   └── order_confirmation_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── checkout_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── cart_page.dart
│   │   │   │   ├── checkout_page.dart
│   │   │   │   └── order_confirmation_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── cart_item.dart
│   │   │   │   ├── cart_summary.dart
│   │   │   │   ├── checkout_form.dart
│   │   │   │   ├── payment_method_selector.dart
│   │   │   │   └── order_details.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── cart_cubit.dart
│   │   │       ├── checkout_cubit.dart
│   │   │       └── order_confirmation_cubit.dart
│   │   │
│   │   └── checkout_injection.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── notifications_remote_datasource.dart
│   │   │   │   └── notifications_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── notification_model.dart
│   │   │   │   └── notification_settings_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── notifications_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   ├── notifications_list_page.dart
│   │   │   │   └── notification_settings_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── notification_card.dart
│   │   │   │   ├── notification_list.dart
│   │   │   │   └── notification_settings_form.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       ├── notifications_cubit.dart
│   │   │       └── notification_settings_cubit.dart
│   │   │
│   │   └── notifications_injection.dart
│   │
│   ├── faq/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── faq_remote_datasource.dart
│   │   │   │   └── faq_local_datasource.dart
│   │   │   │
│   │   │   ├── models/
│   │   │   │   ├── faq_model.dart
│   │   │   │   └── faq_category_model.dart
│   │   │   │
│   │   │   └── repositories/
│   │   │       └── faq_repository.dart
│   │   │
│   │   ├── presentation/
│   │   │   ├── pages/
│   │   │   │   └── faq_page.dart
│   │   │   │
│   │   │   ├── widgets/
│   │   │   │   ├── faq_category_list.dart
│   │   │   │   ├── faq_item.dart
│   │   │   │   ├── faq_search.dart
│   │   │   │   └── faq_expansion_list.dart
│   │   │   │
│   │   │   └── cubits/
│   │   │       └── faq_cubit.dart
│   │   │
│   │   └── faq_injection.dart
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── loading_overlay.dart
│       │   ├── error_display.dart
│       │   ├── empty_state.dart
│       │   ├── section_header.dart
│       │   └── rating_display.dart
│       │
│       └── models/
│           ├── location_model.dart
│           ├── address_model.dart
│           └── pagination_model.dart
│
├── models/
│   ├── base_model.dart             # Základná trieda pre modely (s metódami toJson/fromJson)
│   ├── post_model.dart             # Model pre Post
│   ├── product_model.dart          # Model pre Product (vrátane variant)
│   ├── service_model.dart          # Model pre Service
│   ├── event_model.dart            # Model pre Event
│   ├── user_model.dart             # Model pre User (vrátane rolí a preferencií)
│   ├── review_model.dart           # Model pre Review
│   ├── category_model.dart         # Model pre Category
│   ├── tag_model.dart              # Model pre Tag
│   ├── order_model.dart            # Model pre Order
│   ├── order_item_model.dart       # Model pre Order Item
│   ├── booking_model.dart          # Model pre Booking
│   ├── notification_model.dart     # Model pre Notification
│   ├── faq_model.dart              # Model pre FAQ
│   ├── media_model.dart            # Model pre Media
│   ├── location_model.dart         # Model pre Location (hierarchická)
│   ├── cart_model.dart             # Model pre Cart (ak je e-shop)
│   ├── cart_item_model.dart        # Model pre Cart Item
│   ├── payment_method_model.dart   # Model pre Payment Method
│   └── loyalty_points_model.dart   # Model pre Loyalty Points
│
├── providers/
│   ├── app_provider.dart           # Hlavný provider pre aplikáciu (téma, jazyk, pripojenie)
│   ├── auth_provider.dart          # Provider pre auth stav (prihlásený používateľ)
│   ├── connectivity_provider.dart  # Provider pre sieťové pripojenie (offline/online)
│   ├── theme_provider.dart         # Provider pre tému (light/dark)
│   ├── locale_provider.dart        # Provider pre lokalizáciu (jazyk)
│   ├── cart_provider.dart          # Provider pre košík (ak je e-shop)
│   ├── wishlist_provider.dart      # Provider pre sledované položky
│   └── location_provider.dart      # Provider pre geolokačné dáta
│
├── routes/
│   ├── app_router.dart             # Hlavný router pre navigáciu
│   ├── route_guards.dart           # Ochrany pre routy (napr. prihlásený používateľ)
│   └── deep_link_handler.dart      # Spracovanie deep linkov
│
└── main.dart                       # Hlavný entry point
```

---

### 4.2. Hlavné funkcie aplikácie
#### **Prihlásenie / Registrácia**
- **Firebase Authentication**:
  - Email + heslo
  - Google Sign-In
  - Apple Sign-In (ak je potrebné)
  - Facebook Sign-In (ak je potrebné)
- **WordPress JWT Authentication**:
  - Prihlásenie pomocou WordPress API (pre prístup k chráneným endpointom)
  - Uloženie JWT tokenu v `SecureStorage`
  - Automatické obnovovanie tokenu (refresh token)
- **Biometrické prihlásenie**:
  - Podpora pre Face ID / Touch ID (na zariadeniach, ktoré to podporujú)
- **Sociálne siete**:
  - Možnosť prihlásenia pomocou sociálnych sietí (Facebook, Google, Apple)
- **Registrácia**:
  - Výber role (customer, vendor, organizer)
  - Validácia vstupov (heslo, email, CAPTCHA)
  - Odsielanie potvrdzovacieho emailu (ak je potrebné)
- **Obnovenie hesla**:
  - Formulár pre obnovenie hesla
  - Odsielanie emailu s linkom na obnovenie
- **Sociálna registrácia**:
  - Automatické vytvorenie účtu na základe social profilu
  - Možnosť doplnenia chýbajúcich údajov

#### **Zoznamy a filtrovanie**
- **Infinite scroll**:
  - Načítanie dát po dosiahnutí konca zoznamu
  - Podpora pre pull-to-refresh
  - Indikácia načítavania (shimmer efekt)
- **Filtrovanie**:
  - Filtrovanie podľa kategórií, ceny, dostupnosti, dátumu, lokácie, typu
  - Možnosť uložiť filtre ako predvolené
  - Dynamické filtrovanie (napr. pre produkty: kategória + cena + stav)
  - Filtrovanie podľa viacerých kritérií súčasne
- **Full-text search**:
  - Vyhľadávanie v rámci všetkých entít (Posts, Products, Services, Events, Users, FAQ)
  - Autocomplete pre vyhľadávanie
  - História vyhľadávania (uložená v cache)
  - Odporúčanie vyhľadávania (podľa popularity)
- **Zoradenie**:
  - Podľa relevance, dátumu, ceny, hodnotenia, názvu
  - Možnosť uložiť preferencie zoradenia
  - Dynamické zoradenie (napr. produkty podľa predaja)

#### **Detailné stránky**
- **Načítanie dát**:
  - Fetch dát z API pre konkrétnu entitu
  - Zobrazenie načítavacieho indikátora (shimmer)
  - Cache dát pre offline režim
- **Zobrazenie obrázkov**:
  - Načítanie obrázkov s cache (`cached_network_image`)
  - Podpora pre galériu obrázkov (swipe medzi obrázkami)
  - Zobrazenie placeholderov pre načítavanie
  - Možnosť zoomu na obrázky
- **Sdíľanie obsahu**:
  - Tlačidlo pre zdieľanie (Share button) s možnosťou vybrať aplikáciu
  - Generovanie URL pre deep linking
- **Interakcie**:
  - Možnosť pridania do obľúbených (favorites)
  - Možnosť hodnotenia (rating)
  - Možnosť pridania komentáru (ak je relevantné)
  - Možnosť sledovania autora/poskytovateľa (follow)
- **Deep linking**:
  - Otvorenie konkrétnej stránky pomocou URL (napr. `bolt://products/123`)
  - Podpora pre App Links (Android) a Universal Links (iOS)
  - Automatické presmerovanie na detailnú stránku pri kliknutí na notifikáciu

#### **Offline režim**
- **Cache dát**:
  - Uloženie dát v Hive (pre rýchle načítanie)
  - Uloženie dát v SharedPreferences (pre malé dáta, napr. nastavenia)
  - Uloženie dát v SQLite (pre komplexnejšie dáta, napr. košík)
  - Cache API odpovedí (pre offline použitie)
- **Synchronizácia**:
  - Automatická synchronizácia pri obnovení pripojenia
  - Manuálna synchronizácia (tlačidlo "Synchronizovať")
  - Konfliktové riešenie (posledná zmena vyhráva)
  - Indikácia potreby synchronizácie (napr. "Máte neaktualizované dáta")
- **Upozornenia**:
  - Upozornenie na offline stav (snack bar)
  - Upozornenie na potrebu synchronizácie
  - Upozornenie na neuložené zmeny (napr. pri pridávaní recenzie)

#### **SEO optimalizácia**
- **Dynamické meta tagy**:
  - Generovanie meta tagov pre webové zobrazenie (pomocou `flutter_html` alebo `url_launcher`)
  - Zobrazenie meta tagov v aplikácii (pre sociálne siete)
- **Deep linking**:
  - Konfigurácia pre otvorenie konkrétnej stránky z URL
  - Podpora pre App Links (Android) a Universal Links (iOS)
  - Generovanie URL pre zdieľanie (napr. `bolt://products/123`)
- **Open Graph tagy**:
  - Generovanie OG tagov pre sociálne siete
  - Možnosť manuálneho nastavenia pre konkrétne stránky
- **Sitemap a robots.txt**:
  - Načítanie sitemapy z WordPress a zobrazenie v aplikácii
  - Zobrazenie pravidiel z robots.txt
  - Generovanie dynamických URL pre SEO

#### **Notifikácie**
- **Firebase Cloud Messaging (FCM)**:
  - Prijímanie notifikácií z Firebase
  - Zobrazenie notifikácií v aplikácii (v notifikačnej lište)
  - Kategorizácia notifikácií (general, order, booking, event, promotion)
- **Lokálne notifikácie**:
  - Nastavenie pripomienok (napr. udalosti, rezervácie)
  - Notifikácie o blížiacich sa udalostiach
  - Notifikácie o zmenách v sledovaných položkách
- **Upozornenia**:
  - Notifikácie o nových príspevkoch, produktoch, službách, udalostiach
  - Notifikácie o zmenách v sledovaných položkách
  - Notifikácie o nových recenziách
  - Notifikácie o špeciálnych ponukách

#### **Recenzie a hodnotenia**
- **Zobrazenie recenzií**:
  - Zoznam recenzií pre danú entitu (produkt, služba, udalosť)
  - Filtrovanie recenzií (podľa hodnotenia, dátumu)
  - Zobrazenie priemerného hodnotenia (hviezdičky)
  - Zobrazenie detailov recenzie (pros, cons, doporučenie)
- **Pridanie recenzie**:
  - Formulár pre pridanie recenzie (hodnotenie, text, titulok)
  - Možnosť pridania obrázkov
  - Validácia vstupov (min. počet znakov, povinné polia)
  - Odsielanie recenzie na server
- **Hodnotenie**:
  - Zobrazenie priemerného hodnotenia
  - Možnosť hodnotiť (ak je používateľ prihlásený)
  - Možnosť sledovania recenzií (follow autora recenzie)

#### **Košík a objednávky (ak je e-shop)**
- **Košík**:
  - Pridanie produktu do košíka
  - Zobrazenie košíka s možnosťou editácie
  - Výpočet celkovej ceny, daní, dopravy
  - Aplikácia zľavy (ak je k dispozícii)
  - Možnosť uloženia košíka pre neskoršie použitie
- **Objednávka**:
  - Formulár pre dokončenie objednávky
  - Výber platobnej metódy (karta, PayPal, bankový prevod, platba na mieste)
  - Zobrazenie sumára objednávky
  - Potvrdenie objednávky
  - Zobrazenie potvrdenia objednávky (s číslom objednávky)
- **História objednávok**:
  - Zoznam objednávok používateľa
  - Detail objednávky (položky, cena, stav)
  - Možnosť opakovania objednávky
  - Možnosť stiahnutia faktúry (ak je k dispozícii)

#### **Rezervácie (ak sú služby)**
- **Rezervácia služby**:
  - Formulár pre rezerváciu (dátum, čas, počet osôb)
  - Výber poskytovateľa (ak je služba poskytovaná viacerými)
  - Zobrazenie dostupnosti (kalendár)
  - Výber platobnej metódy (ak je potrebné)
  - Potvrdenie rezervácie (emailom + v aplikácii)
- **Moje rezervácie**:
  - Zoznam rezervácií používateľa
  - Detail rezervácie (dátum, čas, poskytovateľ, cena)
  - Možnosť zrušenia rezervácie (ak je dovolené)
  - Možnosť opakovania rezervácie
  - Notifikácie o blížiacej sa rezervácii

#### **Udalosti**
- **Registrácia na udalosť**:
  - Formulár pre registráciu (meno, email, počet osôb)
  - Výber typu registrácie (fyzická, online)
  - Zobrazenie kapacity a dostupnosti
  - Výber platobnej metódy (ak je potrebné)
  - Potvrdenie registrácie (emailom + v aplikácii)
- **Moje udalosti**:
  - Zoznam registrovaných udalostí
  - Detail udalosti (dátum, čas, lokalita, program)
  - Možnosť odhlásenia sa z udalosti
  - Notifikácie o blížiacej sa udalosti
  - Možnosť sledovania udalosti (follow)

#### **Profil používateľa**
- **Detail profilu**:
  - Zobrazenie informácií o používateľovi (meno, bio, profilová fotografia)
  - Zoznam vytvorených položiek (Posts, Products, Services, Events)
  - Zoznam sledovaných položiek (follow)
  - Zoznam recenzií používateľa
  - Zoznam aktivít používateľa (história objednávok, rezervácií, udalostí)
- **Editácia profilu**:
  - Formulár pre editáciu profilu
  - Nahratie profilovej fotografie
  - Zmena hesla
  - Zmena preferencií (jazyk, notifikácie)
  - Zmena kontaktnej adresy
- **Moje aktivity**:
  - Zoznam objednávok, rezervácií, registrovaných udalostí
  - Možnosť sledovať konkrétne položky (follow)
  - Možnosť hodnotiť položky
  - Možnosť pridania do obľúbených

#### **Sledovanie položiek (Follow)**
- **Pridanie do sledovaných**:
  - Tlačidlo "Sledovať" na detailných stránkach
  - Notifikácie o zmenách v sledovanej položke
  - Zobrazenie sledovaných položiek v profile
- **Odstránenie zo sledovaných**:
  - Tlačidlo "Zrušiť sledovanie" na detailných stránkach
  - Automatické odstránenie zo zoznamu sledovaných
- **Notifikácie**:
  - Notifikácie o nových príspevkoch, produktoch, službách, udalostiach
  - Notifikácie o zmenách v sledovanej položke (napr. nová recenzia, zmena ceny)

#### **Porovnanie produktov (ak je e-shop)**
- **Pridanie produktov do porovnania**:
  - Tlačidlo "Porovnať" na produktových kartách
  - Zobrazenie porovnania v samostatnej stránke
- **Zobrazenie porovnania**:
  - Tabuľkové zobrazenie vlastností produktov
  - Zvýraznenie rozdielov medzi produktmi
  - Možnosť odstránenia produktov z porovnania
- **Export porovnania**:
  - Možnosť exportu porovnania do PDF
  - Možnosť zdieľania porovnania

#### **Obľúbené položky (Wishlist)**
- **Pridanie do obľúbených**:
  - Tlačidlo "Pridať do obľúbených" na produktových kartách
  - Zobrazenie obľúbených položiek v profile
- **Zobrazenie obľúbených**:
  - Zoznam obľúbených položiek
  - Možnosť pridania položiek do košíka
  - Možnosť odstránenia položiek z obľúbených
- **Export/import obľúbených**:
  - Možnosť exportu obľúbených položiek
  - Možnosť importu obľúbených položiek (z iného zariadenia)

#### **Loyalty program (ak je aktivovaný)**
- **Zobrazenie loyalty bodov**:
  - Zobrazenie aktuálneho počtu bodov v profile
  - Zobrazenie histórie ziskov a výdajov bodov
- **Používanie bodov**:
  - Možnosť použitia bodov pri nákupe
  - Možnosť výmeny bodov za výhody
- **Notifikácie o bodoch**:
  - Notifikácie o zisku nových bodov
  - Notifikácie o blížiacej sa exspirácii bodov

#### **Viackrokový proces (napr. checkout, registrácia)**
- **Checkout proces**:
  - Viackrokový formulár (osobné údaje, dodacia adresa, platba)
  - Validácia vstupov v každom kroku
  - Zobrazenie sumára pred dokončením objednávky
  - Potvrdenie objednávky
- **Registrácia**:
  - Viackrokový formulár (osobné údaje, heslo, preferencie)
  - Validácia vstupov v každom kroku
  - Odsielanie potvrdzovacieho emailu

#### **Geolokačné služby**
- **Zobrazenie lokácií**:
  - Zobrazenie lokácií na mape (Google Maps / Mapbox)
  - Zobrazenie detailov lokácie (adresa, kontakt, otváracie hodiny)
- **Filtrovanie podľa lokácie**:
  - Filtrovanie udalostí/služieb podľa aktuálnej polohy
  - Filtrovanie udalostí/služieb podľa zadané lokácie
- **Navigácia k lokácii**:
  - Tlačidlo "Navigovať" (otvorenie v Google Maps / Apple Maps)
  - Zobrazenie trasy k lokácii

#### **Viacjazyčnosť (i18n)**
- **Podpora viacerých jazykov**:
  - English, Slovak, Czech, German, etc.
  - Dynamické načítanie prekladov z WordPress (pomocou WPML alebo Polylang)
- **Formátovanie dát**:
  - Formátovanie dátumov, cien, čísel podľa lokality
  - Podpora pre RTL jazyky (arabčina, hebrejčina)
- **Preklady v aplikácii**:
  - Preklady UI textov (tlačidlá, nadpisy, chybové správy)
  - Preklady obsahu (produkty, služby, udalosti)

#### **Témy a štýly**
- **Light/Dark mód**:
  - Podpora pre systémové nastavenie (follow system)
  - Možnosť manuálneho prepnutia
- **Branding**:
  - Prispôsobenie podľa brandingu klienta (farby, fonty, logo)
  - Možnosť dynamického načítania štýlu z WordPress (pomocou JetThemeCore)
- **Animácie**:
  - Page transitions (fade, slide, scale)
  - Loading indikátory (shimmer, spinner)
  - Micro-interactions (napr. srdiečko pre pridanie do obľúbených)

#### **Responzívny dizajn**
- **Adaptácia na rôzne veľkosti obrazoviek**:
  - Mobil (320px - 480px)
  - Tablet (481px - 768px)
  - Desktop (769px+)
- **Mobilné optimalizácie**:
  - Dotykové prvky (väčšie tlačidlá)
  - Swipe na navigáciu medzi stránkami
  - Optimalizácia pre portrait a landscape režim
- **Adaptívne layouty**:
  - Grid vs. list zobrazenie (podľa veľkosti obrazovky)
  - Zmena veľkosti fontov a medzier

#### **Prístupnosť**
- **Kontrastné farby**:
  - Podpora pre vysoký kontrast (pre zrakovo postihnutých)
- **Text-to-speech**:
  - Podpora pre screen readery (VoiceOver, TalkBack)
- **Klávesnicové skratky**:
  - Podpora pre navigáciu pomocou klávesnice
- **Veľkosť textu**:
  - Možnosť zväčšenia textu (zoom)
- **Označenie obrázkov**:
  - Alt text pre obrázky (pre screen readery)

#### **Animácie a efekty**
- **Page transitions**:
  - Fade, slide, scale, rotation
- **Loading indikátory**:
  - Shimmer efekt pre zoznamy
  - Spinner pre detailné stránky
- **Micro-interactions**:
  - Srdiečko pre pridanie do obľúbených
  - Hviezda pre hodnotenie
  - Zvonec pre notifikácie
  - Animácia pre pridanie do košíka

---

## 5. Backend Integrácia
### 5.1. WordPress Pluginy
- **JetEngine** (posledná verzia)
  - Pre custom post types, meta fields, relations
  - Pre filtrovanie a vyhľadávanie
  - Pre hierarchické taxonomie (kategórie, lokácie)
  - Pre dynamické meta polia
- **ACF (Advanced Custom Fields) Pro**
  - Pre rozšírené custom fields (ak nie sú dostupné v JetEngine)
- **Yoast SEO / Rank Math**
  - Pre SEO optimalizáciu
  - Pre generovanie meta tagov a sitemap
- **WooCommerce** (ak sú potrebné e-shop funkcie)
  - Pre správu produktov, objednávok, platieb
  - Pre správu variant produktov
  - Pre správu zľav a akcií
- **WP REST API / WP GraphQL**
  - Pre API endpointy
  - Pre optimalizované dotazy
- **WPML / Polylang** (ak je potrebná viacjazyčnosť)
  - Pre správu prekladov
  - Pre dynamické načítanie jazykov
- **WP Mail SMTP**
  - Pre odosielanie emailov (potvrdenia, notifikácie)
- **WP Security Audit Log**
  - Pre sledovanie zmien v systéme
- **UpdraftPlus**
  - Pre zálohovanie databázy
- **Redis Object Cache**
  - Pre rýchlejšie načítanie stránok
- **JetThemeCore**
  - Pre dynamické načítanie štýlu z WordPress
- **WPForms / Gravity Forms**
  - Pre formulárové stránky (kontakt, registrácia)
- **MonsterInsights**
  - Pre Google Analytics 4 integáciu
- **WP Statistics**
  - Pre sledovanie návštevnosti

### 5.2. Firebase Integracia
#### **Authentication**
- Email + heslo
- Google Sign-In
- Apple Sign-In (ak je potrebné)
- Facebook Sign-In (ak je potrebné)
- Automatické vytvorenie účtu na základe social profilu

#### **Firestore / Realtime Database**
- **Uloženie offline dát**:
  - Products, Services, Events, Users, Orders, Bookings
  - Cache pre API odpovede
- **Synchronizácia zmien**:
  - Automatická synchronizácia pri obnovení pripojenia
  - Konfliktové riešenie (posledná zmena vyhráva)
- **Štruktúra kolekcií**:
  - `users/{userId}/profile` (profil používateľa)
  - `users/{userId}/favorites` (obľúbené položky)
  - `users/{userId}/reviews` (hodnotenia)
  - `users/{userId}/orders` (objednávky)
  - `users/{userId}/bookings` (rezervácie)
  - `users/{userId}/notifications` (notifikácie)
  - `cache/{entityType}/{entityId}` (cache pre API odpovede)
  - `cart/{userId}` (košík používateľa)
  - `wishlist/{userId}` (obľúbené položky)
  - `activity/{userId}` (história aktivít)

#### **Cloud Functions**
- **Spracovanie webhookov z WordPress**:
  - Posielanie notifikácií pri nových položkách
  - Synchronizácia dát medzi WordPress a Firebase
- **Notifikácie**:
  - Posielanie notifikácií používateľom (FCM)
  - Notifikácie o zmenách v sledovaných položkách
- **Automatické akcie**:
  - Odosielanie potvrdzovacích emailov pri registrácii
  - Odosielanie notifikácií o blížiacej sa udalosti
  - Odosielanie notifikácií o zmene stavu objednávky

#### **Analytics**
- **Trackovanie používateľského správania**:
  - Ktoré stránky používatelia navštevujú
  - Ktoré položky sledujú
  - Ktoré akcie vykonávajú (kliknutia, pridanie do košíka)
- **A/B testovanie**:
  - Testovanie rôznych verzií UI
  - Testovanie rôznych variant produktov

#### **Crash Reporting**
- **Firebase Crashlytics**
  - Sledovanie chýb v aplikácii
  - Automatické reporty o chybách
- **Sentry** (alternatíva)
  - Podpora pre viacero platforiem
  - Detailnejšie reporty o chybách

#### **Performance Monitoring**
- **Firebase Performance Monitoring**
  - Sledovanie rýchlosti načítania stránok
  - Sledovanie času načítania API
- **Flutter DevTools**
  - Sledovanie výkonu aplikácie
  - Profilovanie pamäte a CPU

---

## 6. Bezpečnosť
### 6.1. API Bezpečnosť
- **JWT Authentication**:
  - Tokeny s obmedzenou platnosťou (15-30 minút)
  - Refresh tokeny pre automatické obnovovanie
  - Ošetrenie expired tokenov
  - Tokeny šifrované v `SecureStorage`
- **Rate limiting**:
  - Obmedzenie počtu API volaní za časové obdobie
  - Ošetrenie DoS útokov
  - Konfigurácia na strane WordPress (pomocou pluginov)
- **HTTPS**:
  - Povinné pre všetky API volania
  - Overenie certifikátu
- **CORS**:
  - Konfigurácia CORS pre WordPress API
  - Obmedzenie prístupu len na potrebné domény
- **Input validation**:
  - Validácia vstupov na strane klienta aj servera
  - Ošetrenie SQL injection, XSS, CSRF
  - Sanitizácia vstupov (odstránenie HTML tagov, SQL kódu)

### 6.2. Lokálna bezpečnosť
- **Šifrované uloženie dát**:
  - JWT tokeny uložené v `SecureStorage` (šifrované)
  - Citlivé dáta (heslá, API keys) uložené v `flutter_secure_storage`
  - Heslá používateľov uložené v hashovanej forme
- **Obfuskácia kódu**:
  - ProGuard pre Android
  - Obfuscation pre iOS (podpora pre App Store)
- **SecureStorage**:
  - Pre uloženie citlivých dát (tokeny, heslá)
- **Biometrické overenie**:
  - Podpora pre Face ID / Touch ID pre citlivé akcie
  - Možnosť zapnutia/vypnutia biometrického overenia
- **Ochrana pred reverse engineering**:
  - Obfuskácia kódu (obfuscation)
  - Zakázanie debug módu v produkčnom prostredí
  - Používanie Flutter's `flutter run --release`

### 6.3. WordPress Bezpečnosť
- **Regularné aktualizácie**:
  - WordPress, pluginy, témy
- **Hardening**:
  - Zmena prefixu tabuliek (`wp_` → `custom_prefix_`)
  - Obmedzenie admin prístupu (len z konkrétnych IP)
  - Zakázanie editácie súborov z WordPress adminu
  - Zakázanie XML-RPC (ak nie je potrebné)
  - Používanie silných hesiel pre admin účty
  - Dvojsúčtové overenie (2FA) pre admin účty
- **Plugin Security**:
  - Wordfence / Sucuri Security
  - Regularné skenovanie na malware
  - Blokovanie škodlivých IP adries
- **Zálohovanie**:
  - Denné zálohy databázy
  - Zálohovanie súborov
  - Offsite zálohovanie (cloud storage)
- **Monitorovanie**:
  - Sledovanie neobvyklých aktivít (neúspešné prihlásenia)
  - Automatické blokovanie IP po viacerých neúspešných pokusoch
  - Logovanie zmien v systéme

### 6.4. Firebase Bezpečnosť
- **Firebase Rules**:
  - Konfigurácia pravidiel pre Firestore (len čítanie/zápis pre autentifikovaných používateľov)
  - Konfigurácia pravidiel pre Realtime Database
  - Obmedzenie prístupu len na potrebné kolekcie
- **API Keys**:
  - Obmedzenie prístupu k Firebase API keys
  - Používanie environment variables pre API keys
  - Rotácia API keys v pravidelných intervaloch
- **Autentifikácia**:
  - Obmedzenie metód prihlásenia (len overené metódy)
  - Monitorovanie neobvyklých aktivít (viaceré pokusy o prihlásenie)
  - Dvojsúčtové overenie (2FA) pre citlivé účty

---

## 7. Testovanie
### 7.1. Unit Testy
- **Testovanie modelov (DTO)**:
  - Testovanie serializácie/deserializácie JSON
  - Testovanie validácie dát (email, heslo, URL)
  - Testovanie metód `toJson`/`fromJson`
- **Testovanie služieb (API volania)**:
  - Testovanie fetch dát z API
  - Testovanie chybových stavov (404, 500, 401)
  - Testovanie cache služieb
  - Testovanie Firebase služieb
- **Testovanie logiky**:
  - Filtrovanie, zoradenie, vyhľadávanie
  - Validácia formulárov
  - Výpočet cien, daní, dopravy
- **Testovanie cache**:
  - Testovanie uloženia a načítania dát z cache
  - Testovanie konfliktového riešenia

### 7.2. Widget Testy
- **Testovanie jednotlivých widgetov**:
  - Testovanie zobrazenia widgetu
  - Testovanie interakcií (kliknutie, swipe, long press)
  - Testovanie stavov (loading, error, empty)
- **Testovanie stránok**:
  - Testovanie celého flow stránky
  - Testovanie navigácie medzi stránkami
  - Testovanie formulárov
- **Testovanie formulárov**:
  - Testovanie validácie vstupov
  - Testovanie odosielania formulára
  - Testovanie chybových stavov

### 7.3. Integračné Testy
- **Testovanie celého flow aplikácie**:
  - Prihlásenie → Zoznam → Detail → Návrat
  - Nákup produktu (ak je e-shop)
  - Rezervácia služby
  - Registrácia na udalosť
  - Pridanie recenzie
- **Testovanie offline režimu**:
  - Načítanie dát offline
  - Synchronizácia dát
  - Konfliktové riešenie
- **Testovanie notifikácií**:
  - Prijatie notifikácie
  - Kliknutie na notifikáciu
  - Zobrazenie notifikácie v aplikácii

### 7.4. End-to-End Testy
- **Testovanie API endpointov**:
  - Posielanie requestov a overenie odpovedí
  - Testovanie chybových stavov
  - Testovanie autentifikácie
- **Testovanie celého používateľského flow**:
  - Používateľské scenáre (user stories)
  - Testovanie výkonu (loading times)
  - Testovanie stability (dlhodobé používanie)
- **Testovanie bezpečnosti**:
  - Testovanie zraniteľností (SQL injection, XSS)
  - Testovanie autentifikácie a autorizácie
  - Testovanie ochrany citlivých údajov

### 7.5. Testovacie nástroje
- **Unit testy**: `test` package (Dart)
- **Widget testy**: `flutter_test` package
- **Integračné testy**: `integration_test` package
- **API testy**: Postman / Insomnia
- **Performance testy**: Flutter DevTools
- **Crash testy**: Firebase Crashlytics
- **Automatizované testy**: GitHub Actions / GitLab CI
- **Testovanie prístupnosti**: axe-core / Lighthouse
- **Testovanie lokalizácie**: Flutter's `flutter_localizations`

---

## 8. Nasadenie
### 8.1. CI/CD Pipeline
- **GitHub Actions / GitLab CI**:
  - **Testovanie**:
    - Unit testy
    - Widget testy
    - Integračné testy
    - End-to-end testy
  - **Code Quality**:
    - Analýza kódu (Dart Analyze, Flutter Analyze)
    - Kontrola formátovania (dart format)
    - Kontrola bezpečnostných zraniteľností
  - **Build**:
    - Build APK (Android)
    - Build App Bundle (Android)
    - Build IPA (iOS)
    - Build Web (ak je potrebné)
  - **Beta testovanie**:
    - Nasadenie na Firebase App Distribution (Android)
    - Nasadenie na TestFlight (iOS)
  - **Produkčné nasadenie**:
    - Nasadenie na Google Play Store
    - Nasadenie na Apple App Store
- **Konfigurácia pipeline**:
  - `.github/workflows/flutter_ci.yml` / `.gitlab-ci.yml`
  - Environment variables pre API keys, Firebase config
  - Cache pre závislosti (pubspec.yaml)
  - Cache pre buildy (pre rýchlejšie nasadenie)

### 8.2. Monitorovanie
#### **Crash Reporting**
- **Firebase Crashlytics**:
  - Automatické reporty o chybách
  - Sledovanie chýb podľa verzie aplikácie
  - Prioritizácia chýb podľa frekvencie výskytu
- **Sentry**:
  - Alternatíva k Crashlytics
  - Podpora pre viacero platforiem
  - Detailnejšie reporty o chybách

#### **Performance Monitoring**
- **Firebase Performance Monitoring**:
  - Sledovanie rýchlosti načítania stránok
  - Sledovanie času načítania API
  - Sledovanie rýchlosti renderovania widgetov
- **Flutter DevTools**:
  - Sledovanie výkonu aplikácie
  - Profilovanie pamäte a CPU
  - Sledovanie sietového trafficu

#### **Analytics**
- **Firebase Analytics**:
  - Sledovanie používateľského správania
  - A/B testovanie
  - Sledovanie konverzií
- **Google Analytics 4**:
  - Sledovanie webového zobrazenia (ak je relevantné)
  - Sledovanie používateľského flow
  - Sledovanie udalostí (kliknutia, pridanie do košíka)

#### **Monitorovanie API**
- **WordPress**:
  - WP Statistics / MonsterInsights
  - Sledovanie API volaní
  - Sledovanie chybových stavov
- **Firebase**:
  - Sledovanie API volaní z aplikácie
  - Sledovanie chybových stavov
  - Sledovanie rýchlosti odpovedí

#### **Monitorovanie Notifikácií**
- **Firebase Cloud Messaging**:
  - Sledovanie doručených notifikácií
  - Sledovanie otvorených notifikácií
  - Sledovanie konverzií z notifikácií

### 8.3. Aktualizácie
- **Automatické aktualizácie**:
  - Firebase Remote Config pre dynamické nastavenia
  - Overenie verzie aplikácie pri spustení
  - Notifikácia o novej verzii
- **Manuálne aktualizácie**:
  - Notifikácia o novej verzii
  - Tlačidlo pre aktualizáciu (smeruje na App Store / Google Play)
- **A/B testovanie**:
  - Testovanie rôznych verzií UI
  - Testovanie rôznych variant funkcií

---

## 9. Dokumentácia
### 9.1. Technická dokumentácia
- **Architektúra aplikácie**:
  - Diagramy (Flowchart, UML, Architektúrny diagram)
  - Popis jednotlivých komponentov
  - Popis dátových tokov
- **API dokumentácia**:
  - Swagger / OpenAPI špecifikácia
  - Postman kolekcia
  - Popis endpointov, parametrov, odpovedí
- **Databázové schéma**:
  - ER diagram
  - Popis tabuliek a ich vzťahov
  - Popis indexov a optimalizácií
- **Bezpečnosť**:
  - Popis bezpečnostných opatrení
  - Návod na konfiguráciu WordPress a Firebase
  - Popis autentifikačných metód
- **Testovanie**:
  - Popis testovacích scenárov
  - Výsledky testovania
  - Popis testovacích nástrojov

### 9.2. Používateľská dokumentácia
- **Návod na inštaláciu**:
  - Ako nainštalovať aplikáciu
  - Požadované zariadenie (Android/iOS verzia)
  - Podporované operačné systémy
- **FAQ**:
  - Často kladené otázky
  - Riešenie problémov
  - Kontakt na podporu
- **Kontakt na podporu**:
  - Email, telefón, sociálne siete
  - Formulár pre kontaktovanie podpory
- **Návod na používanie**:
  - Ako používateľ aplikáciu používa
  - Príklady použitia jednotlivých funkcií
  - Návod na registráciu, prihlásenie, nákup
- **Podmienky používania**:
  - Podmienky pre používateľov
  - Podmienky pre nákup
  - Podmienky pre rezerváciu
- **Ochrana osobných údajov**:
  - GDPR compliance
  - Zoznam spracovávaných údajov
  - Práva používateľov
```
