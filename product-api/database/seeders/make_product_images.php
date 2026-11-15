<?php
/**
 * Generates simple illustrated product images for the seeder.
 * Run once:  php database/seeders/make_product_images.php
 * Output:    database/seeders/images/*.jpg
 */

$out = __DIR__ . '/images';
@mkdir($out, 0777, true);

function canvas(array $top, array $bottom)
{
    $s = 800;
    $im = imagecreatetruecolor($s, $s);
    imageantialias($im, true);
    for ($y = 0; $y < $s; $y++) {
        $t = $y / $s;
        $c = imagecolorallocate(
            $im,
            (int) ($top[0] + ($bottom[0] - $top[0]) * $t),
            (int) ($top[1] + ($bottom[1] - $top[1]) * $t),
            (int) ($top[2] + ($bottom[2] - $top[2]) * $t)
        );
        imageline($im, 0, $y, $s - 1, $y, $c);
    }
    // soft floor shadow
    $sh = imagecolorallocatealpha($im, 0, 0, 0, 105);
    imagefilledellipse($im, 400, 700, 420, 60, $sh);
    return $im;
}

function rgb($im, $r, $g, $b, $a = 0)
{
    return imagecolorallocatealpha($im, $r, $g, $b, $a);
}

function roundRect($im, $x1, $y1, $x2, $y2, $r, $col)
{
    imagefilledrectangle($im, $x1 + $r, $y1, $x2 - $r, $y2, $col);
    imagefilledrectangle($im, $x1, $y1 + $r, $x2, $y2 - $r, $col);
    imagefilledellipse($im, $x1 + $r, $y1 + $r, $r * 2, $r * 2, $col);
    imagefilledellipse($im, $x2 - $r, $y1 + $r, $r * 2, $r * 2, $col);
    imagefilledellipse($im, $x1 + $r, $y2 - $r, $r * 2, $r * 2, $col);
    imagefilledellipse($im, $x2 - $r, $y2 - $r, $r * 2, $r * 2, $col);
}

function label($im, $text, $cx, $cy, $col, $scale = 5)
{
    // scale the built-in bitmap font up for a bold, chunky label
    $f = 5;
    $w = imagefontwidth($f) * strlen($text);
    $h = imagefontheight($f);
    $tmp = imagecreatetruecolor($w, $h);
    imagesavealpha($tmp, true);
    imagefill($tmp, 0, 0, imagecolorallocatealpha($tmp, 0, 0, 0, 127));
    $c = imagecolorsforindex($im, $col);
    imagestring($tmp, $f, 0, 0, $text, imagecolorallocate($tmp, $c['red'], $c['green'], $c['blue']));
    imagecopyresampled($im, $tmp, (int) ($cx - $w * $scale / 2), (int) ($cy - $h * $scale / 2), 0, 0, $w * $scale, $h * $scale, $w, $h);
}

function save($im, $path)
{
    // downsample for smooth edges
    $small = imagecreatetruecolor(600, 600);
    imagecopyresampled($small, $im, 0, 0, 0, 0, 600, 600, 800, 800);
    imagejpeg($small, $path, 90);
}

// 1) Cola can
$im = canvas([255, 228, 230], [255, 205, 210]);
roundRect($im, 270, 170, 530, 690, 40, rgb($im, 220, 38, 38));
imagefilledrectangle($im, 290, 150, 510, 185, rgb($im, 200, 200, 210));
imagefilledrectangle($im, 290, 675, 510, 705, rgb($im, 200, 200, 210));
imagefilledrectangle($im, 300, 200, 330, 660, rgb($im, 255, 255, 255, 80)); // shine
imagesetthickness($im, 14);
imagearc($im, 400, 470, 220, 60, 20, 160, rgb($im, 255, 255, 255));
label($im, 'COLA', 400, 380, rgb($im, 255, 255, 255), 7);
label($im, '330ml', 400, 520, rgb($im, 255, 230, 230), 4);
save($im, "$out/coca-cola.jpg");

// 2) Water bottle
$im = canvas([224, 242, 254], [191, 225, 250]);
roundRect($im, 350, 110, 450, 190, 14, rgb($im, 37, 99, 235)); // cap
roundRect($im, 330, 180, 470, 250, 30, rgb($im, 147, 197, 253, 30));
roundRect($im, 280, 230, 520, 690, 70, rgb($im, 147, 197, 253, 30));
roundRect($im, 280, 380, 520, 540, 0, rgb($im, 255, 255, 255));
imagefilledrectangle($im, 305, 260, 330, 660, rgb($im, 255, 255, 255, 70)); // shine
label($im, 'WATER', 400, 440, rgb($im, 37, 99, 235), 5);
label($im, '500ml', 400, 505, rgb($im, 96, 165, 250), 3);
save($im, "$out/water.jpg");

// 3) Chips bag
$im = canvas([254, 249, 195], [253, 230, 138]);
$pts = [250, 170, 550, 170, 580, 420, 550, 680, 250, 680, 220, 420];
imagefilledpolygon($im, $pts, rgb($im, 234, 88, 12));
imagefilledrectangle($im, 250, 160, 550, 200, rgb($im, 194, 65, 12));
imagefilledrectangle($im, 250, 650, 550, 690, rgb($im, 194, 65, 12));
imagefilledellipse($im, 400, 470, 230, 170, rgb($im, 253, 224, 71));
imagefilledellipse($im, 360, 460, 90, 60, rgb($im, 250, 204, 21));
imagefilledellipse($im, 440, 495, 90, 60, rgb($im, 250, 204, 21));
label($im, 'CHIPS', 400, 290, rgb($im, 255, 255, 255), 6);
save($im, "$out/chips.jpg");

// 4) Grape juice carton
$im = canvas([243, 232, 255], [221, 214, 254]);
imagefilledpolygon($im, [290, 230, 400, 140, 510, 230], rgb($im, 167, 139, 250));
imagefilledrectangle($im, 290, 230, 510, 690, rgb($im, 124, 58, 237));
imagefilledrectangle($im, 440, 120, 465, 190, rgb($im, 236, 72, 153)); // straw
for ($i = 0; $i < 6; $i++) {
    imagefilledellipse($im, 360 + ($i % 3) * 40, 430 + intdiv($i, 3) * 40, 46, 46, rgb($im, 216, 180, 254));
}
imagefilledellipse($im, 400, 510, 46, 46, rgb($im, 216, 180, 254));
label($im, 'GRAPE', 400, 320, rgb($im, 255, 255, 255), 5);
label($im, 'JUICE', 400, 610, rgb($im, 237, 233, 254), 4);
save($im, "$out/grape-juice.jpg");

echo "Images written to $out\n";
