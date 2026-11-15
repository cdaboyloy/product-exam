<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('products', function (Blueprint $table) {
            $table->id('ProductID');                               // bigint(20) UNSIGNED AUTO_INCREMENT
            $table->string('ProductName', 100);                    // varchar(100) NOT NULL
            $table->string('Description', 255)->nullable();        // varchar(255) NULL
            $table->unsignedBigInteger('CategoryID');              // bigint(20) UNSIGNED NOT NULL
            $table->string('Barcode', 255)->nullable();            // varchar(255) NULL
            $table->date('Expiredate')->nullable();                // date NULL
            $table->integer('Qty')->default(0);                    // int(11) default 0
            $table->decimal('UnitPriceIn', 10, 2)->default(0.00);  // decimal(10,2) default 0.00
            $table->decimal('UnitPriceOut', 10, 2)->default(0.00); // decimal(10,2) default 0.00
            $table->string('ProductImage', 255)->nullable();       // varchar(255) NULL
            $table->tinyInteger('isDeleted')->default(0);          // tinyint(1) default 0

            $table->index('CategoryID');
            $table->index('Barcode');
            $table->foreign('CategoryID')
                ->references('category_id')->on('categories')
                ->onUpdate('cascade')->onDelete('restrict');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
