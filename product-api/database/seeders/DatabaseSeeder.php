<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Storage;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $drinks = Category::create([
            'category_name' => 'Drinks',
            'description'   => 'Soft drinks, water, juice',
            'image'         => $this->copyImage('water.jpg', 'categories'),
        ]);
        $snacks = Category::create([
            'category_name' => 'Snacks',
            'description'   => 'Chips, cookies, candy',
            'image'         => $this->copyImage('chips.jpg', 'categories'),
        ]);

        Product::create([
            'ProductName' => 'Coca-Cola 330ml', 'Description' => 'Can',
            'CategoryID' => $drinks->category_id, 'Barcode' => '8850999220017',
            'Expiredate' => '2027-06-30', 'Qty' => 48,
            'UnitPriceIn' => 0.40, 'UnitPriceOut' => 0.60,
            'ProductImage' => $this->copyImage('coca-cola.jpg'),
        ]);
        Product::create([
            'ProductName' => 'Mineral Water 500ml', 'Description' => 'Bottle',
            'CategoryID' => $drinks->category_id, 'Barcode' => '8851234567890',
            'Expiredate' => '2027-12-31', 'Qty' => 120,
            'UnitPriceIn' => 0.15, 'UnitPriceOut' => 0.25,
            'ProductImage' => $this->copyImage('water.jpg'),
        ]);
        Product::create([
            'ProductName' => 'Potato Chips', 'Description' => 'Original flavor 50g',
            'CategoryID' => $snacks->category_id, 'Barcode' => '8850001112223',
            'Expiredate' => '2027-03-15', 'Qty' => 30,
            'UnitPriceIn' => 0.50, 'UnitPriceOut' => 0.80,
            'ProductImage' => $this->copyImage('chips.jpg'),
        ]);
        Product::create([
            'ProductName' => 'Grape Juice 250ml', 'Description' => 'Carton',
            'CategoryID' => $drinks->category_id, 'Barcode' => '8850123456789',
            'Expiredate' => '2026-12-20', 'Qty' => 8,
            'UnitPriceIn' => 0.70, 'UnitPriceOut' => 1.10,
            'ProductImage' => $this->copyImage('grape-juice.jpg'),
        ]);
    }

    /** Copy a bundled image (database/seeders/images) into storage/app/public/{folder} */
    private function copyImage(string $file, string $folder = 'products'): string
    {
        $path = "$folder/seed-$file";
        Storage::disk('public')->put($path, file_get_contents(__DIR__ . "/images/$file"));
        return $path;
    }
}
