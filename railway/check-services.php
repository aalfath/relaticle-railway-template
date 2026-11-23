<?php
// Exit 0 when Postgres and Redis both answer, 1 otherwise (quiet).
require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
try {
    Illuminate\Support\Facades\DB::connection()->getPdo();
    Illuminate\Support\Facades\Redis::connection()->ping();
    exit(0);
} catch (Throwable $e) {
    fwrite(STDERR, 'railway-init: not ready yet: '.substr($e->getMessage(), 0, 160).PHP_EOL);
    exit(1);
}
