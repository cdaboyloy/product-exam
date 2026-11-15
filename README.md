# Product Exam — Laravel REST API + Flutter

```
product-exam/
├── product-api/   ← Laravel (Backend / REST API)
└── product_app/   ← Flutter (Mobile app)
```

## ចម្លើយតាមលំដាប់សំណួរ

| # | តម្រូវការ | ឯកសារ |
|---|---|---|
| ១ | បង្កើត Laravel Project | `product-api/` (`composer create-project laravel/laravel product-api`) |
| ២ | Migrations | `product-api/database/migrations/..._create_categories_table.php`<br>`product-api/database/migrations/..._create_products_table.php` |
| ៣ | Models | `product-api/app/Models/Category.php`<br>`product-api/app/Models/Product.php` |
| ៤ | Controllers | `product-api/app/Http/Controllers/Api/CategoryController.php`<br>`product-api/app/Http/Controllers/Api/ProductController.php` |
| ៥ | Methods ទាំង ៥ | `index`, `store`, `show`, `update`, `destroy` (ក្នុង Controllers ទាំងពីរ) |
| ៦ | API Routes | `product-api/routes/api.php` |
| ៧ | Screens | `product_app/lib/screens/` — List, Detail, Add/Edit form |
| ៨ | Dart code ហៅ API | `product_app/lib/services/api_service.dart` |
| ៩ | Record video | អ្នកត្រូវ record ខ្លួនឯង (មើលជំហានខាងក្រោម) |
| ១០ | Zip / GitHub | មើលផ្នែកចុងក្រោយ |

## API Endpoints

| Method | URL | Controller method | មុខងារ |
|---|---|---|---|
| GET | `/api/products` | `index` | បង្ហាញទាំងអស់ (`?search=` ស្វែងរកតាមឈ្មោះ/barcode) |
| POST | `/api/products` | `store` | បញ្ចូលថ្មី |
| GET | `/api/products/{id}` | `show` | បង្ហាញមួយ |
| PUT | `/api/products/{id}` | `update` | កែប្រែ |
| DELETE | `/api/products/{id}` | `destroy` | លុប (កំណត់ `isDeleted = 1`) |

`/api/categories` មាន ៥ methods ដូចគ្នា។

> **ចំណាំ:** `destroy` របស់ products ជា *soft delete* — វាកំណត់ `isDeleted = 1` ជំនួសការលុបចេញពី database ព្រោះ table មាន column `isDeleted`។ `index` និង `show` បង្ហាញតែ products ដែល `isDeleted = 0`។

## ១. Run Laravel API

1. បើក XAMPP → Start **MySQL**
2. បង្កើត database ឈ្មោះ `product_db` ក្នុង phpMyAdmin (utf8mb4_unicode_ci)
3. ពិនិត្យ `product-api/.env`:
   ```
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=product_db
   DB_USERNAME=root
   DB_PASSWORD=          ← ដាក់ password MySQL របស់អ្នក (បើមាន)
   ```
4. Run:
   ```bash
   cd product-api
   php artisan migrate --seed
   php artisan storage:link
   php artisan serve --host=0.0.0.0 --port=8000
   ```
5. សាក: បើក `http://127.0.0.1:8000/api/products`

## ២. Run Flutter App

```bash
cd product_app
flutter pub get
flutter run
```

**Run លើ laptop (Chrome)** — ជ្រើសរូបពី Finder បានផ្ទាល់:
```bash
cd product_app
flutter run -d chrome
```

**សាកលើ iPhone (Safari, មិនត្រូវការ Xcode):**
1. Mac និង iPhone ត្រូវនៅ Wi-Fi តែមួយ (ឬ Mac ភ្ជាប់ Hotspot របស់ iPhone)
2. រក IP របស់ Mac: `ipconfig getifaddr en0`
3. Run API: `cd product-api && php artisan serve --host=0.0.0.0 --port=8000`
4. Build & serve app: `cd product_app && flutter build web && python3 -m http.server 8090 --directory build/web`
5. នៅលើ iPhone បើក Safari → `http://<IP Mac>:8090`
6. (ជម្រើស) Share → **Add to Home Screen** ដើម្បីបើកដូច app

**ដាក់រូបពី laptop ចូល Android Emulator:**
- វិធី ក: អូសរូប (JPG/PNG) ពី Finder ទម្លាក់លើអេក្រង់ emulator
- វិធី ខ (ច្រើនរូបម្ដង): `./product_app/tool/push_images.sh ~/Desktop/រូប-product`
- បន្ទាប់មកក្នុង app: ចុចរូប → "Choose from gallery" → ជ្រើសរូប → ចុច **Done**

URL របស់ API នៅក្នុង `product_app/lib/config.dart`:
- Android Emulator → `http://10.0.2.2:8000/api` (default)
- iOS Simulator / Chrome → `http://127.0.0.1:8000/api` (default)
- ទូរស័ព្ទពិត → ប្ដូរទៅ `http://<IP កុំព្យូទ័រ>:8000/api` (ទូរស័ព្ទ និងកុំព្យូទ័រត្រូវនៅ Wi-Fi តែមួយ)

## ៣. ស្គ្រីបសម្រាប់ Record Video (សំណួរ ៩)

1. បង្ហាញ phpMyAdmin → table `products`
2. បើក app → **បង្ហាញ** បញ្ជី products
3. ចុច **Add Product** → បំពេញ ឈ្មោះ, category, barcode, ថ្ងៃផុតកំណត់, qty, តម្លៃ, រូបភាព → **Save**
4. ចុចលើ product → មើល **Detail**
5. ចុច **Edit** → ប្ដូរ qty/តម្លៃ → **Update**
6. ចុច **Delete** → បញ្ជាក់ → product បាត់ពីបញ្ជី
7. Refresh phpMyAdmin → បង្ហាញថាទិន្នន័យប្រែប្រួល (`isDeleted = 1`)

## ៤. Zip / GitHub (សំណួរ ១០)

**Zip** (មិនរួមបញ្ចូល `vendor` និង `build` ដើម្បីឲ្យតូច):
```bash
cd product-exam/..
zip -r product-exam.zip product-exam -x "*/vendor/*" "*/node_modules/*" "*/build/*" "*/.dart_tool/*" "*.sqlite"
```

**GitHub:**
```bash
cd product-exam
git init && git add . && git commit -m "Product exam: Laravel API + Flutter"
git branch -M main
git remote add origin https://github.com/<username>/product-exam.git
git push -u origin main
```
