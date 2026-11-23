<?php
// Creates the first CRM user (email verified) and a system administrator from
// ADMIN_EMAIL / ADMIN_PASSWORD / ADMIN_NAME, once. Never prints the password.
require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Relaticle\SystemAdmin\Enums\SystemAdministratorRole;
use Relaticle\SystemAdmin\Models\SystemAdministrator;

$email = mb_strtolower(trim((string) getenv('ADMIN_EMAIL')));
$password = (string) getenv('ADMIN_PASSWORD');
$name = trim((string) getenv('ADMIN_NAME')) ?: 'Admin';

if (! filter_var($email, FILTER_VALIDATE_EMAIL)) {
    fwrite(STDERR, "railway-init: ADMIN_EMAIL is not a valid email address, no admin created\n");
    exit(0);
}
if (strlen($password) < 8) {
    fwrite(STDERR, "railway-init: ADMIN_PASSWORD is shorter than 8 characters, no admin created\n");
    exit(0);
}

if (! User::query()->where('email', $email)->exists()) {
    $user = User::query()->forceCreate([
        'name' => $name,
        'email' => $email,
        'password' => Hash::make($password),
    ]);
    $user->markEmailAsVerified();
    echo "railway-init: created CRM user {$email}\n";
}

if (! SystemAdministrator::query()->where('email', $email)->exists()) {
    SystemAdministrator::query()->create([
        'name' => $name,
        'email' => $email,
        'password' => Hash::make($password),
        'email_verified_at' => now(),
        'role' => SystemAdministratorRole::SuperAdministrator,
    ]);
    echo "railway-init: created system administrator {$email}\n";
}
