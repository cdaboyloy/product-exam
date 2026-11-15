<?php

use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ProductController;
use Illuminate\Support\Facades\Route;

/*
| API Routes  (prefix: /api)
|
| GET     /api/categories          → index
| POST    /api/categories          → store
| GET     /api/categories/{id}     → show
| PUT     /api/categories/{id}     → update
| DELETE  /api/categories/{id}     → destroy
|
| GET     /api/products            → index
| POST    /api/products            → store
| GET     /api/products/{id}       → show
| PUT     /api/products/{id}       → update
| DELETE  /api/products/{id}       → destroy
*/

Route::apiResource('categories', CategoryController::class);
Route::apiResource('products', ProductController::class);
