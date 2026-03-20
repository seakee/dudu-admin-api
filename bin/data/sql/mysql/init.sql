SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `sys_permission_role`;
DROP TABLE IF EXISTS `sys_role_user`;
DROP TABLE IF EXISTS `sys_menu`;
DROP TABLE IF EXISTS `sys_user_passkey`;
DROP TABLE IF EXISTS `sys_user_identity`;
DROP TABLE IF EXISTS `sys_operation_record`;
DROP TABLE IF EXISTS `sys_permission`;
DROP TABLE IF EXISTS `sys_role`;
DROP TABLE IF EXISTS `sys_user`;
DROP TABLE IF EXISTS `auth_app`;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE `auth_app`
(
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT,
    `app_id`        varchar(30) NOT NULL,
    `app_name`      varchar(50) DEFAULT NULL,
    `app_secret`    varchar(256) NOT NULL,
    `redirect_uri`  varchar(500) DEFAULT NULL,
    `description`   text,
    `status`        smallint NOT NULL DEFAULT 0,
    `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    datetime DEFAULT NULL,
    `app_id_active` varchar(30) GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN app_id ELSE NULL END) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_auth_app_app_id_active` (`app_id_active`),
    KEY `idx_auth_app_app_name` (`app_name`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_role`
(
    `id`          bigint unsigned NOT NULL AUTO_INCREMENT,
    `name`        varchar(50) DEFAULT NULL,
    `description` varchar(100) DEFAULT NULL,
    `created_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`  datetime DEFAULT NULL,
    `name_active` varchar(50) GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN NULLIF(name, '') ELSE NULL END) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sys_role_name_active` (`name_active`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_user`
(
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT,
    `email`         varchar(200) DEFAULT NULL,
    `phone`         varchar(30) DEFAULT NULL,
    `password`      varchar(255) DEFAULT NULL,
    `totp_key`      char(32) DEFAULT NULL,
    `totp_enabled`  tinyint(1) DEFAULT 0,
    `user_name`     varchar(50) DEFAULT NULL,
    `status`        smallint DEFAULT NULL,
    `avatar`        text,
    `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    datetime DEFAULT NULL,
    `email_active`  varchar(200) GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN NULLIF(email, '') ELSE NULL END) STORED,
    `phone_active`  varchar(30) GENERATED ALWAYS AS (CASE WHEN deleted_at IS NULL THEN NULLIF(phone, '') ELSE NULL END) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sys_user_email_active` (`email_active`),
    UNIQUE KEY `uk_sys_user_phone_active` (`phone_active`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_permission`
(
    `id`               bigint unsigned NOT NULL AUTO_INCREMENT,
    `name`             varchar(50) DEFAULT NULL,
    `perm_type`        varchar(10) DEFAULT NULL,
    `method`           varchar(10) DEFAULT NULL,
    `path`             text,
    `description`      text,
    `perm_group`       text,
    `created_at`       timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       datetime DEFAULT NULL,
    `api_route_active` char(32)
        GENERATED ALWAYS AS (
            CASE
                WHEN deleted_at IS NULL
                     AND perm_type = 'api'
                     AND method IS NOT NULL
                     AND method <> ''
                     AND path IS NOT NULL
                     AND path <> ''
                    THEN MD5(CONCAT(method, ' ', path))
                ELSE NULL
            END
        ) STORED,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sys_permission_api_active` (`api_route_active`),
    KEY `idx_sys_permission_type_deleted` (`perm_type`, `deleted_at`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_menu`
(
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT,
    `name`          varchar(50) DEFAULT NULL,
    `path`          text,
    `permission_id` bigint unsigned DEFAULT NULL,
    `parent_id`     bigint unsigned DEFAULT NULL,
    `icon`          text,
    `sort`          int DEFAULT NULL,
    `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sys_menu_parent_sort` (`parent_id`, `sort`),
    KEY `idx_sys_menu_permission_id` (`permission_id`),
    CONSTRAINT `fk_sys_menu_permission_id`
        FOREIGN KEY (`permission_id`) REFERENCES `sys_permission` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_role_user`
(
    `user_id` bigint unsigned NOT NULL,
    `role_id` bigint unsigned NOT NULL,
    PRIMARY KEY (`user_id`, `role_id`),
    KEY `idx_sys_role_user_role_id` (`role_id`),
    CONSTRAINT `fk_sys_role_user_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_sys_role_user_role_id`
        FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_permission_role`
(
    `role_id`       bigint unsigned NOT NULL,
    `permission_id` bigint unsigned NOT NULL,
    PRIMARY KEY (`role_id`, `permission_id`),
    KEY `idx_sys_permission_role_permission_id` (`permission_id`),
    CONSTRAINT `fk_sys_permission_role_role_id`
        FOREIGN KEY (`role_id`) REFERENCES `sys_role` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT `fk_sys_permission_role_permission_id`
        FOREIGN KEY (`permission_id`) REFERENCES `sys_permission` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_user_identity`
(
    `id`               bigint unsigned NOT NULL AUTO_INCREMENT,
    `user_id`          bigint unsigned NOT NULL,
    `provider`         varchar(50) NOT NULL,
    `provider_tenant`  varchar(200) NOT NULL,
    `provider_subject` varchar(200) NOT NULL,
    `display_name`     varchar(100) DEFAULT NULL,
    `avatar_url`       text,
    `raw_profile_json` json DEFAULT NULL,
    `bound_at`         timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `last_login_at`    datetime DEFAULT NULL,
    `created_at`       timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`       timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`       datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sys_user_identity_provider_subject` (`provider`, `provider_tenant`, `provider_subject`),
    KEY `idx_sys_user_identity_user_id` (`user_id`),
    CONSTRAINT `fk_sys_user_identity_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_user_passkey`
(
    `id`                    bigint unsigned NOT NULL AUTO_INCREMENT,
    `user_id`               bigint unsigned NOT NULL,
    `credential_id`         varchar(512) NOT NULL,
    `credential_public_key` text NOT NULL,
    `sign_count`            bigint unsigned NOT NULL DEFAULT 0,
    `aaguid`                varchar(64) DEFAULT NULL,
    `transports_json`       json DEFAULT NULL,
    `user_handle`           varchar(255) DEFAULT NULL,
    `display_name`          varchar(100) DEFAULT NULL,
    `last_used_at`          datetime DEFAULT NULL,
    `created_at`            timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`            datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_sys_user_passkey_credential_id` (`credential_id`),
    KEY `idx_sys_user_passkey_user_id` (`user_id`),
    CONSTRAINT `fk_sys_user_passkey_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `sys_user` (`id`)
            ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

CREATE TABLE `sys_operation_record`
(
    `id`            bigint unsigned NOT NULL AUTO_INCREMENT,
    `ip`            varchar(50) DEFAULT NULL,
    `method`        varchar(10) DEFAULT NULL,
    `path`          varchar(500) DEFAULT NULL,
    `status`        smallint DEFAULT NULL,
    `latency`       double DEFAULT NULL,
    `agent`         varchar(512) DEFAULT NULL,
    `error_message` text,
    `user_id`       bigint unsigned DEFAULT NULL,
    `params`        text,
    `resp`          text,
    `trace_id`      varchar(64) DEFAULT NULL,
    `created_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `deleted_at`    datetime DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sys_operation_record_created_at` (`created_at`),
    KEY `idx_sys_operation_record_user_id` (`user_id`),
    KEY `idx_sys_operation_record_trace_id` (`trace_id`),
    KEY `idx_sys_operation_record_method` (`method`),
    KEY `idx_sys_operation_record_path` (`path`),
    KEY `idx_sys_operation_record_status` (`status`),
    KEY `idx_sys_operation_record_ip` (`ip`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

INSERT INTO `sys_role` (`id`, `name`, `description`, `created_at`, `updated_at`, `deleted_at`)
VALUES
(1, 'super_admin', '超级管理员', NOW(), NOW(), NULL),
(2, 'base', '基础权限', NOW(), NOW(), NULL);

INSERT INTO `sys_user`
(`id`, `email`, `phone`, `password`, `totp_key`, `totp_enabled`, `user_name`, `status`, `avatar`, `created_at`, `updated_at`, `deleted_at`)
VALUES
(1, 'seakee23@seakee.top', '18590714486', '$2a$12$wkE5.jSgDFdhFvFid1gWrep/TUAtb9Ct8epNyysjCMnYD340m0e0a', 'ILSTDLESL23H2PRZGARHXJHYDLXBPPMO', 1, 'seakee', 1, 'https://s1-imfile.feishucdn.com/static-resource/v1/v3_00gr_511e6ec9-3796-4684-8938-be5b79cc7c5g~?image_size=72x72&cut_type=&quality=&format=image&sticker_format=.webp', NOW(), NOW(), NULL),
(3, 'test@test.test', NULL, '$2y$12$P3Zk3lSMM2dR7yqKCSuUWeopw.pwIs6JL3YBa/PyYp319.Nlqb7eO', NULL, 0, 'test', 1, '', NOW(), NOW(), NULL);

INSERT INTO `sys_permission`
(`id`, `name`, `perm_type`, `method`, `path`, `description`, `perm_group`, `created_at`, `updated_at`, `deleted_at`)
VALUES
(1, '首页', 'menu', NULL, NULL, '首页', NULL, NOW(), NOW(), NULL),
(2, '系统管理', 'menu', NULL, NULL, '系统管理', NULL, NOW(), NOW(), NULL),
(3, '菜单管理', 'menu', NULL, NULL, '菜单管理', NULL, NOW(), NOW(), NULL),
(4, '权限管理', 'menu', NULL, NULL, '用户权限', NULL, NOW(), NOW(), NULL),
(5, '系统用户', 'menu', NULL, NULL, '用户管理', NULL, NOW(), NOW(), NULL),
(6, '角色管理', 'menu', NULL, NULL, '角色管理', NULL, NOW(), NOW(), NULL),
(7, '获取权限列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/paginate', '获取权限列表', 'sys-permission', NOW(), NOW(), NULL),
(8, '新增权限', 'api', 'POST', '/dudu-admin-api/internal/admin/system/permission', '新增权限', 'sys-permission', NOW(), NOW(), NULL),
(9, '修改权限', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/permission', '修改权限', 'sys-permission', NOW(), NOW(), NULL),
(10, '删除权限', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/permission', '删除权限', 'sys-permission', NOW(), NOW(), NULL),
(11, '获取可用权限列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/available', '获取可用权限列表', 'sys-permission', NOW(), NOW(), NULL),
(12, '获取菜单列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/menu/list', '获取菜单列表', 'sys-menu', NOW(), NOW(), NULL),
(13, '新增菜单', 'api', 'POST', '/dudu-admin-api/internal/admin/system/menu', '新增菜单', 'sys-menu', NOW(), NOW(), NULL),
(14, '修改菜单', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/menu', '修改菜单', 'sys-menu', NOW(), NOW(), NULL),
(15, '获取菜单详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/menu', '获取菜单详情', 'sys-menu', NOW(), NOW(), NULL),
(16, '删除菜单', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/menu', '删除菜单', 'sys-menu', NOW(), NOW(), NULL),
(17, '获取权限详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission', '获取权限详情', 'sys-permission', NOW(), NOW(), NULL),
(18, '获取角色列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/paginate', '获取角色列表', 'sys-role', NOW(), NOW(), NULL),
(19, '新增角色', 'api', 'POST', '/dudu-admin-api/internal/admin/system/role', '新增角色', 'sys-role', NOW(), NOW(), NULL),
(20, '修改角色', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/role', '修改角色', 'sys-role', NOW(), NOW(), NULL),
(21, '获取角色详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role', '获取角色详情', 'sys-role', NOW(), NOW(), NULL),
(22, '删除角色', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/role', '删除角色', 'sys-role', NOW(), NOW(), NULL),
(23, '获取角色对应的权限', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/permission', '获取角色对应的权限', 'sys-role', NOW(), NOW(), NULL),
(24, '配置角色权限', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/role/permission', '配置角色对应的权限', 'sys-role', NOW(), NOW(), NULL),
(25, '获取所有角色列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/list', '获取所有角色列表', 'sys-role', NOW(), NOW(), NULL),
(26, '获取用户列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/paginate', '获取用户列表', 'sys-user', NOW(), NOW(), NULL),
(27, '新增用户', 'api', 'POST', '/dudu-admin-api/internal/admin/system/user', '新增用户', 'sys-user', NOW(), NOW(), NULL),
(28, '修改用户', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user', '修改用户', 'sys-user', NOW(), NOW(), NULL),
(29, '获取用户详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user', '获取用户详情', 'sys-user', NOW(), NOW(), NULL),
(30, '删除用户', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user', '删除用户', 'sys-user', NOW(), NOW(), NULL),
(31, '获取用户角色', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/role', '获取用户角色', 'sys-user', NOW(), NOW(), NULL),
(32, '配置用户角色', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/role', '配置用户角色', 'sys-user', NOW(), NOW(), NULL),
(33, '获取用户菜单', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/menus', '获取用户菜单', 'sys-base', NOW(), NOW(), NULL),
(34, '获取用户信息', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/profile', '获取用户信息', 'sys-base', NOW(), NOW(), NULL),
(35, '修改用户信息', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/profile', '修改用户信息', 'sys-base', NOW(), NOW(), NULL),
(36, '获取所有权限', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/list', '获取所有权限', 'sys-permission', NOW(), NOW(), NULL),
(37, '修改密码', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/password', '修改密码', 'sys-base', NOW(), NOW(), NULL),
(38, '获取 TFA 状态', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/tfa/status', '获取 TFA 状态', 'sys-base', NOW(), NOW(), NULL),
(39, '拉取2FA密钥/二维码', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/tfa/key', '开启 2FA 时拉取密钥/二维码', 'sys-base', NOW(), NOW(), NULL),
(40, '启用 2FA', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/tfa/enable', '启用 2FA', 'sys-base', NOW(), NOW(), NULL),
(41, '禁用 2FA', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/tfa/disable', '禁用 2FA', 'sys-base', NOW(), NOW(), NULL),
(42, '修改账号', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/identifier', '修改账号', 'sys-base', NOW(), NOW(), NULL),
(43, '获取 OAuth 登录地址', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/oauth/url', '获取 OAuth 登录地址', 'sys-base', NOW(), NOW(), NULL),
(44, '操作记录', 'menu', NULL, NULL, '操作记录', 'sys-menu', NOW(), NOW(), NULL),
(45, '获取 Passkey 敏感操作验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/passkey/options', '获取 Passkey 敏感操作验证请求', 'sys-base', NOW(), NOW(), NULL),
(46, '获取操作记录详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/record/detail', '获取操作记录详情', 'sys-operation', NOW(), NOW(), NULL),
(47, '本地账号重认证', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth', '本地账号重认证', 'sys-base', NOW(), NOW(), NULL),
(48, '获取 Passkey 登录验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/login/options', '获取 Passkey 登录验证请求', 'sys-base', NOW(), NOW(), NULL),
(49, '删除用户全部 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user/passkeys', '删除用户全部 Passkey', 'sys-user', NOW(), NOW(), NULL),
(50, '获取操作记录分页', 'api', 'GET', '/dudu-admin-api/internal/admin/system/record/paginate', '获取操作记录分页', 'sys-operation', NOW(), NOW(), NULL),
(51, '获取用户 Passkey', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/passkeys', '获取用户 Passkey', 'sys-user', NOW(), NOW(), NULL),
(52, '确认第三方绑定', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/oauth/bind/confirm', '确认第三方绑定', 'sys-base', NOW(), NOW(), NULL),
(53, '完成 Passkey 敏感操作验证', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/passkey/finish', '完成 Passkey 敏感操作验证', 'sys-base', NOW(), NOW(), NULL),
(54, '完成 Passkey 注册', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/register/finish', '完成 Passkey 注册', 'sys-base', NOW(), NOW(), NULL),
(55, '解绑第三方', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/oauth/unbind', '解绑第三方', 'sys-base', NOW(), NOW(), NULL),
(56, '获取 Passkey 注册验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/register/options', '获取 Passkey 注册验证请求', 'sys-base', NOW(), NOW(), NULL),
(57, '禁用用户 TFA', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/tfa/disable', '禁用用户 TFA', 'sys-user', NOW(), NOW(), NULL),
(58, '重置用户密码', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/password/reset', '重置用户密码', 'sys-user', NOW(), NOW(), NULL),
(59, 'TOTP 验证敏感操作', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/totp', 'TOTP 验证敏感操作', 'sys-base', NOW(), NOW(), NULL),
(60, '获取敏感操作验证方式', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/reauth/methods', '获取敏感操作验证方式', 'sys-base', NOW(), NOW(), NULL),
(61, '密码验证敏感操作', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/password', '密码验证敏感操作', 'sys-base', NOW(), NOW(), NULL),
(62, '获取当前用户 Passkey', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/passkeys', '获取当前用户 Passkey', 'sys-base', NOW(), NOW(), NULL),
(63, '完成 Passkey 登录', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/login/finish', '完成 Passkey 登录', 'sys-base', NOW(), NOW(), NULL),
(64, '删除用户 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user/passkey', '删除用户 Passkey', 'sys-user', NOW(), NOW(), NULL),
(65, '重置密码（安全码）', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/password/reset', '重置密码（安全码）', 'sys-base', NOW(), NOW(), NULL),
(66, '获取角色菜单权限树', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/permission/menu-tree', '获取角色菜单权限树', 'sys-role', NOW(), NOW(), NULL),
(67, '删除当前用户 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/auth/passkey', '删除当前用户 Passkey', 'sys-base', NOW(), NOW(), NULL),
(68, '获取已绑定第三方', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/oauth/accounts', '获取已绑定第三方', 'sys-base', NOW(), NOW(), NULL),
(69, '换取登录 Token', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/token', '换取登录 Token', 'sys-base', NOW(), NOW(), NULL);

INSERT INTO `sys_menu`
(`id`, `name`, `path`, `permission_id`, `parent_id`, `icon`, `sort`, `created_at`, `updated_at`, `deleted_at`)
VALUES
(1, '首页', '/home', 1, 0, 'HomeFilled', 0, NOW(), NOW(), NULL),
(2, '系统管理', '/system', 2, 0, 'Tools', 1, NOW(), NOW(), NULL),
(3, '菜单管理', '/system/menu', 3, 2, 'Menu', 3, NOW(), NOW(), NULL),
(4, '权限管理', '/system/permission', 4, 2, 'fa-solid fa-lock', 2, NOW(), NOW(), NULL),
(5, '系统用户', '/system/user', 5, 2, 'fa-solid fa-users', 0, NOW(), NOW(), NULL),
(6, '角色管理', '/system/role', 6, 2, 'fa-solid fa-user-shield', 1, NOW(), NOW(), NULL),
(7, '操作记录', '/system/operation', 44, 2, 'fa-solid fa-bars', 4, NOW(), NOW(), NULL);

INSERT INTO `sys_role_user` (`user_id`, `role_id`)
VALUES
(1, 1),
(3, 1),
(3, 2);

INSERT INTO `sys_permission_role` (`role_id`, `permission_id`)
VALUES
(2, 1),
(2, 33),
(2, 34),
(2, 35),
(2, 37),
(2, 38),
(2, 39),
(2, 40),
(2, 41),
(2, 42),
(2, 45),
(2, 53),
(2, 54),
(2, 55),
(2, 56),
(2, 59),
(2, 60),
(2, 61),
(2, 62),
(2, 67),
(2, 68);

INSERT INTO `auth_app`
(`id`, `app_id`, `app_name`, `app_secret`, `redirect_uri`, `description`, `status`, `created_at`, `updated_at`, `deleted_at`)
VALUES
(1, 'dudu-admin-api-bootstrap', 'dudu-admin-api bootstrap', 'PLEASE_CHANGE_ME_BOOTSTRAP_SECRET', 'http://127.0.0.1:3000', 'Bootstrap app for cold start. Replace secret before production.', 1, NOW(), NOW(), NULL);

ALTER TABLE `auth_app` AUTO_INCREMENT = 2;
ALTER TABLE `sys_role` AUTO_INCREMENT = 3;
ALTER TABLE `sys_user` AUTO_INCREMENT = 4;
ALTER TABLE `sys_permission` AUTO_INCREMENT = 70;
ALTER TABLE `sys_menu` AUTO_INCREMENT = 8;
ALTER TABLE `sys_user_identity` AUTO_INCREMENT = 1;
ALTER TABLE `sys_user_passkey` AUTO_INCREMENT = 1;
ALTER TABLE `sys_operation_record` AUTO_INCREMENT = 1;
