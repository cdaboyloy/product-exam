<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProductController extends Controller
{
    // 1. index — GET /api/products?search=...&category_id=...
    public function index(Request $request): JsonResponse
    {
        $query = Product::with('category')->active();

        if ($search = $request->query('search')) {
            $query->where(function ($q) use ($search) {
                $q->where('ProductName', 'like', "%{$search}%")
                  ->orWhere('Barcode', 'like', "%{$search}%");
            });
        }

        if ($categoryId = $request->query('category_id')) {
            $query->where('CategoryID', $categoryId);
        }

        return response()->json([
            'success' => true,
            'data'    => $query->orderByDesc('ProductID')->get(),
        ]);
    }

    // 2. store — POST /api/products
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate($this->rules());

        if ($request->hasFile('ProductImage')) {
            $validated['ProductImage'] = $request->file('ProductImage')->store('products', 'public');
        }

        $product = Product::create($validated)->load('category');

        return response()->json([
            'success' => true,
            'message' => 'Product created successfully',
            'data'    => $product,
        ], 201);
    }

    // 3. show — GET /api/products/{id}
    public function show(string $id): JsonResponse
    {
        $product = Product::with('category')->active()->find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Product not found'], 404);
        }

        return response()->json(['success' => true, 'data' => $product]);
    }

    // 4. update — PUT/PATCH /api/products/{id}
    //    (Flutter ផ្ញើរូបភាពជាមួយ POST + _method=PUT)
    public function update(Request $request, string $id): JsonResponse
    {
        $product = Product::active()->find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Product not found'], 404);
        }

        $validated = $request->validate($this->rules(true));

        if ($request->hasFile('ProductImage')) {
            $this->deleteLocalImage($product->ProductImage);
            $validated['ProductImage'] = $request->file('ProductImage')->store('products', 'public');
        }

        $product->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Product updated successfully',
            'data'    => $product->fresh('category'),
        ]);
    }

    // 5. destroy — DELETE /api/products/{id}
    //    Soft delete: កំណត់ isDeleted = 1 (មិនលុបចេញពី database ពិតប្រាកដ)
    public function destroy(string $id): JsonResponse
    {
        $product = Product::active()->find($id);
        if (!$product) {
            return response()->json(['success' => false, 'message' => 'Product not found'], 404);
        }

        $product->update(['isDeleted' => 1]);

        return response()->json(['success' => true, 'message' => 'Product deleted successfully']);
    }

    private function rules(bool $isUpdate = false): array
    {
        $req = $isUpdate ? 'sometimes|required' : 'required';

        return [
            'ProductName'  => "$req|string|max:100",
            'Description'  => 'nullable|string|max:255',
            'CategoryID'   => "$req|integer|exists:categories,category_id",
            'Barcode'      => 'nullable|string|max:255',
            'Expiredate'   => 'nullable|date',
            'Qty'          => 'nullable|integer|min:0',
            'UnitPriceIn'  => 'nullable|numeric|min:0',
            'UnitPriceOut' => 'nullable|numeric|min:0',
            // Image is required for a new product; optional when editing (keeps the old one)
            'ProductImage' => ($isUpdate ? 'nullable' : 'required') . '|image|max:4096',
        ];
    }

    private function deleteLocalImage(?string $path): void
    {
        if ($path && !str_starts_with($path, 'http')) {
            Storage::disk('public')->delete($path);
        }
    }
}
