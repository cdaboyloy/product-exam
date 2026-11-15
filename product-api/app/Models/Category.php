<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Category extends Model
{
    protected $table = 'categories';
    protected $primaryKey = 'category_id';

    protected $fillable = [
        'category_name',
        'description',
        'image',
    ];

    protected $appends = ['image_url'];

    public function products(): HasMany
    {
        return $this->hasMany(Product::class, 'CategoryID', 'category_id');
    }

    public function getImageUrlAttribute(): ?string
    {
        if (!$this->image) return null;
        if (str_starts_with($this->image, 'http')) return $this->image;
        return url(Storage::url($this->image));
    }
}
