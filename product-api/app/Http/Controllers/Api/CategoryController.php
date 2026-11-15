<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class CategoryController extends Controller
{
    // 1. index — GET /api/categories
    public function index(): JsonResponse
    {
        $categories = Category::orderBy('category_name')->get();

        return response()->json([
            'success' => true,
            'data'    => $categories,
        ]);
    }

    // 2. store — POST /api/categories
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'category_name' => 'required|string|max:50',
            'description'   => 'nullable|string|max:255',
            'image'         => 'required', // file រូបភាព ឬ string (URL/path)
        ]);

        $validated['image'] = $this->resolveImage($request) ?? $validated['image'];

        $category = Category::create($validated);

        return response()->json([
            'success' => true,
            'message' => 'Category created successfully',
            'data'    => $category,
        ], 201);
    }

    // 3. show — GET /api/categories/{id}
    public function show(string $id): JsonResponse
    {
        $category = Category::find($id);
        if (!$category) {
            return response()->json(['success' => false, 'message' => 'Category not found'], 404);
        }

        return response()->json(['success' => true, 'data' => $category]);
    }

    // 4. update — PUT/PATCH /api/categories/{id}
    public function update(Request $request, string $id): JsonResponse
    {
        $category = Category::find($id);
        if (!$category) {
            return response()->json(['success' => false, 'message' => 'Category not found'], 404);
        }

        $validated = $request->validate([
            'category_name' => 'sometimes|required|string|max:50',
            'description'   => 'nullable|string|max:255',
            'image'         => 'sometimes|required',
        ]);

        if ($path = $this->resolveImage($request)) {
            $this->deleteLocalImage($category->image);
            $validated['image'] = $path;
        }

        $category->update($validated);

        return response()->json([
            'success' => true,
            'message' => 'Category updated successfully',
            'data'    => $category,
        ]);
    }

    // 5. destroy — DELETE /api/categories/{id}
    public function destroy(string $id): JsonResponse
    {
        $category = Category::find($id);
        if (!$category) {
            return response()->json(['success' => false, 'message' => 'Category not found'], 404);
        }

        if ($category->products()->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Cannot delete: this category still has products',
            ], 409);
        }

        $this->deleteLocalImage($category->image);
        $category->delete();

        return response()->json(['success' => true, 'message' => 'Category deleted successfully']);
    }

    private function resolveImage(Request $request): ?string
    {
        if ($request->hasFile('image')) {
            $request->validate(['image' => 'image|max:4096']);
            return $request->file('image')->store('categories', 'public');
        }
        return null;
    }

    private function deleteLocalImage(?string $path): void
    {
        if ($path && !str_starts_with($path, 'http')) {
            Storage::disk('public')->delete($path);
        }
    }
}
