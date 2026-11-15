<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    protected $table = 'products';
    protected $primaryKey = 'ProductID';
    public $timestamps = false; // table products មិនមាន created_at / updated_at

    protected $fillable = [
        'ProductName',
        'Description',
        'CategoryID',
        'Barcode',
        'Expiredate',
        'Qty',
        'UnitPriceIn',
        'UnitPriceOut',
        'ProductImage',
        'isDeleted',
    ];

    protected $casts = [
        'CategoryID'   => 'integer',
        'Qty'          => 'integer',
        'UnitPriceIn'  => 'decimal:2',
        'UnitPriceOut' => 'decimal:2',
        'Expiredate'   => 'date:Y-m-d',
        'isDeleted'    => 'boolean',
    ];

    protected $appends = ['image_url'];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'CategoryID', 'category_id');
    }

    // យកតែ products ដែលមិនទាន់លុប
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('isDeleted', 0);
    }

    public function getImageUrlAttribute(): ?string
    {
        if (!$this->ProductImage) return null;
        if (str_starts_with($this->ProductImage, 'http')) return $this->ProductImage;
        return url(Storage::url($this->ProductImage));
    }
}
