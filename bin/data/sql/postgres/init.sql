BEGIN;

SET search_path TO public;

DROP TABLE IF EXISTS sys_permission_role CASCADE;
DROP TABLE IF EXISTS sys_role_user CASCADE;
DROP TABLE IF EXISTS sys_menu CASCADE;
DROP TABLE IF EXISTS sys_user_passkey CASCADE;
DROP TABLE IF EXISTS sys_user_identity CASCADE;
DROP TABLE IF EXISTS sys_operation_record CASCADE;
DROP TABLE IF EXISTS sys_permission CASCADE;
DROP TABLE IF EXISTS sys_role CASCADE;
DROP TABLE IF EXISTS sys_user CASCADE;
DROP TABLE IF EXISTS auth_app CASCADE;
DROP FUNCTION IF EXISTS set_updated_at() CASCADE;

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE auth_app
(
    id           bigserial PRIMARY KEY,
    app_id       varchar(30)  NOT NULL,
    app_name     varchar(50)  DEFAULT NULL,
    app_secret   varchar(256) NOT NULL,
    redirect_uri varchar(500) DEFAULT NULL,
    description  text,
    status       smallint     NOT NULL DEFAULT 0,
    created_at   timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at   timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at   timestamp    DEFAULT NULL
);

CREATE UNIQUE INDEX uk_auth_app_app_id_active
    ON auth_app (app_id)
    WHERE deleted_at IS NULL;
CREATE INDEX idx_auth_app_app_name ON auth_app (app_name);

CREATE TABLE sys_role
(
    id          bigserial PRIMARY KEY,
    name        varchar(50)  DEFAULT NULL,
    description varchar(100) DEFAULT NULL,
    created_at  timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at  timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at  timestamp    DEFAULT NULL
);

CREATE UNIQUE INDEX uk_sys_role_name_active
    ON sys_role (name)
    WHERE deleted_at IS NULL AND name IS NOT NULL AND name <> '';

CREATE TABLE sys_user
(
    id           bigserial PRIMARY KEY,
    email        varchar(200) DEFAULT NULL,
    phone        varchar(30)  DEFAULT NULL,
    password     varchar(255) DEFAULT NULL,
    totp_key     char(32)     DEFAULT NULL,
    totp_enabled boolean      DEFAULT FALSE,
    user_name    varchar(50)  DEFAULT NULL,
    status       smallint     DEFAULT NULL,
    avatar       text,
    created_at   timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at   timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at   timestamp    DEFAULT NULL
);

CREATE UNIQUE INDEX uk_sys_user_email_active
    ON sys_user (email)
    WHERE deleted_at IS NULL AND email IS NOT NULL AND email <> '';
CREATE UNIQUE INDEX uk_sys_user_phone_active
    ON sys_user (phone)
    WHERE deleted_at IS NULL AND phone IS NOT NULL AND phone <> '';

CREATE TABLE sys_permission
(
    id          bigserial PRIMARY KEY,
    name        varchar(50) DEFAULT NULL,
    perm_type   varchar(10) DEFAULT NULL,
    method      varchar(10) DEFAULT NULL,
    path        text,
    description text,
    perm_group  text,
    created_at  timestamp   DEFAULT CURRENT_TIMESTAMP,
    updated_at  timestamp   DEFAULT CURRENT_TIMESTAMP,
    deleted_at  timestamp   DEFAULT NULL
);

CREATE UNIQUE INDEX uk_sys_permission_api_active
    ON sys_permission (method, path)
    WHERE deleted_at IS NULL
      AND perm_type = 'api'
      AND method IS NOT NULL
      AND path IS NOT NULL
      AND method <> ''
      AND path <> '';
CREATE INDEX idx_sys_permission_type_deleted
    ON sys_permission (perm_type, deleted_at);

CREATE TABLE sys_menu
(
    id            bigserial PRIMARY KEY,
    name          varchar(50) DEFAULT NULL,
    path          text,
    permission_id bigint      DEFAULT NULL,
    parent_id     bigint      DEFAULT NULL,
    icon          text,
    sort          integer     DEFAULT NULL,
    created_at    timestamp   DEFAULT CURRENT_TIMESTAMP,
    updated_at    timestamp   DEFAULT CURRENT_TIMESTAMP,
    deleted_at    timestamp   DEFAULT NULL
);

CREATE INDEX idx_sys_menu_parent_sort ON sys_menu (parent_id, sort);
CREATE INDEX idx_sys_menu_permission_id ON sys_menu (permission_id);

CREATE TABLE sys_role_user
(
    user_id bigint NOT NULL,
    role_id bigint NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

CREATE INDEX idx_sys_role_user_role_id ON sys_role_user (role_id);

CREATE TABLE sys_permission_role
(
    role_id       bigint NOT NULL,
    permission_id bigint NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

CREATE INDEX idx_sys_permission_role_permission_id ON sys_permission_role (permission_id);

CREATE TABLE sys_user_identity
(
    id               bigserial PRIMARY KEY,
    user_id          bigint       NOT NULL,
    provider         varchar(50)  NOT NULL,
    provider_tenant  varchar(200) NOT NULL,
    provider_subject varchar(200) NOT NULL,
    display_name     varchar(100) DEFAULT NULL,
    avatar_url       text,
    raw_profile_json text         DEFAULT NULL,
    bound_at         timestamp    DEFAULT CURRENT_TIMESTAMP,
    last_login_at    timestamp    DEFAULT NULL,
    created_at       timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at       timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at       timestamp    DEFAULT NULL
);

CREATE UNIQUE INDEX uk_sys_user_identity_provider_subject
    ON sys_user_identity (provider, provider_tenant, provider_subject);
CREATE INDEX idx_sys_user_identity_user_id
    ON sys_user_identity (user_id);

CREATE TABLE sys_user_passkey
(
    id                    bigserial PRIMARY KEY,
    user_id               bigint       NOT NULL,
    credential_id         varchar(512) NOT NULL,
    credential_public_key text         NOT NULL,
    sign_count            bigint       NOT NULL DEFAULT 0,
    aaguid                varchar(64)  DEFAULT NULL,
    transports_json       text         DEFAULT NULL,
    user_handle           varchar(255) DEFAULT NULL,
    display_name          varchar(100) DEFAULT NULL,
    last_used_at          timestamp    DEFAULT NULL,
    created_at            timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at            timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at            timestamp    DEFAULT NULL
);

CREATE UNIQUE INDEX uk_sys_user_passkey_credential_id
    ON sys_user_passkey (credential_id);
CREATE INDEX idx_sys_user_passkey_user_id
    ON sys_user_passkey (user_id);

CREATE TABLE sys_operation_record
(
    id            bigserial PRIMARY KEY,
    ip            varchar(50)  DEFAULT NULL,
    method        varchar(10)  DEFAULT NULL,
    path          varchar(500) DEFAULT NULL,
    status        smallint     DEFAULT NULL,
    latency       double precision DEFAULT NULL,
    agent         varchar(512) DEFAULT NULL,
    error_message text,
    user_id       bigint       DEFAULT NULL,
    params        text,
    resp          text,
    trace_id      varchar(64)  DEFAULT NULL,
    created_at    timestamp    DEFAULT CURRENT_TIMESTAMP,
    updated_at    timestamp    DEFAULT CURRENT_TIMESTAMP,
    deleted_at    timestamp    DEFAULT NULL
);

CREATE INDEX idx_sys_operation_record_created_at ON sys_operation_record (created_at DESC);
CREATE INDEX idx_sys_operation_record_user_id ON sys_operation_record (user_id);
CREATE INDEX idx_sys_operation_record_trace_id ON sys_operation_record (trace_id);
CREATE INDEX idx_sys_operation_record_method ON sys_operation_record (method);
CREATE INDEX idx_sys_operation_record_path ON sys_operation_record (path);
CREATE INDEX idx_sys_operation_record_status ON sys_operation_record (status);
CREATE INDEX idx_sys_operation_record_ip ON sys_operation_record (ip);

ALTER TABLE sys_menu
    ADD CONSTRAINT fk_sys_menu_permission_id
        FOREIGN KEY (permission_id) REFERENCES sys_permission (id)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE sys_role_user
    ADD CONSTRAINT fk_sys_role_user_user_id
        FOREIGN KEY (user_id) REFERENCES sys_user (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_sys_role_user_role_id
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE sys_permission_role
    ADD CONSTRAINT fk_sys_permission_role_role_id
        FOREIGN KEY (role_id) REFERENCES sys_role (id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_sys_permission_role_permission_id
        FOREIGN KEY (permission_id) REFERENCES sys_permission (id)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE sys_user_identity
    ADD CONSTRAINT fk_sys_user_identity_user_id
        FOREIGN KEY (user_id) REFERENCES sys_user (id)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE sys_user_passkey
    ADD CONSTRAINT fk_sys_user_passkey_user_id
        FOREIGN KEY (user_id) REFERENCES sys_user (id)
        ON UPDATE CASCADE ON DELETE RESTRICT;

CREATE TRIGGER trg_auth_app_set_updated_at
    BEFORE UPDATE ON auth_app
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_role_set_updated_at
    BEFORE UPDATE ON sys_role
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_user_set_updated_at
    BEFORE UPDATE ON sys_user
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_permission_set_updated_at
    BEFORE UPDATE ON sys_permission
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_menu_set_updated_at
    BEFORE UPDATE ON sys_menu
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_user_identity_set_updated_at
    BEFORE UPDATE ON sys_user_identity
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_user_passkey_set_updated_at
    BEFORE UPDATE ON sys_user_passkey
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_sys_operation_record_set_updated_at
    BEFORE UPDATE ON sys_operation_record
    FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

INSERT INTO sys_role (id, name, description, created_at, updated_at, deleted_at)
VALUES
(1, 'super_admin', '超级管理员', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(2, 'base', '基础权限', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

INSERT INTO sys_user (id, email, phone, password, totp_key, totp_enabled, user_name, status, avatar, created_at, updated_at, deleted_at)
VALUES
(1, 'seakee23@seakee.top', '18590714486', '$2a$12$wkE5.jSgDFdhFvFid1gWrep/TUAtb9Ct8epNyysjCMnYD340m0e0a', 'ILSTDLESL23H2PRZGARHXJHYDLXBPPMO', TRUE, 'seakee', 1, 'https://s1-imfile.feishucdn.com/static-resource/v1/v3_00gr_511e6ec9-3796-4684-8938-be5b79cc7c5g~?image_size=72x72&cut_type=&quality=&format=image&sticker_format=.webp', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(3, 'test@test.test', NULL, '$2y$12$P3Zk3lSMM2dR7yqKCSuUWeopw.pwIs6JL3YBa/PyYp319.Nlqb7eO', NULL, FALSE, 'test', 1, '', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

INSERT INTO sys_permission (id, name, perm_type, method, path, description, perm_group, created_at, updated_at, deleted_at)
VALUES
(1, '首页', 'menu', NULL, NULL, '首页', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(2, '系统管理', 'menu', NULL, NULL, '系统管理', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(3, '菜单管理', 'menu', NULL, NULL, '菜单管理', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(4, '权限管理', 'menu', NULL, NULL, '用户权限', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(5, '系统用户', 'menu', NULL, NULL, '用户管理', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(6, '角色管理', 'menu', NULL, NULL, '角色管理', NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(7, '获取权限列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/paginate', '获取权限列表', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(8, '新增权限', 'api', 'POST', '/dudu-admin-api/internal/admin/system/permission', '新增权限', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(9, '修改权限', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/permission', '修改权限', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(10, '删除权限', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/permission', '删除权限', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(11, '获取可用权限列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/available', '获取可用权限列表', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(12, '获取菜单列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/menu/list', '获取菜单列表', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(13, '新增菜单', 'api', 'POST', '/dudu-admin-api/internal/admin/system/menu', '新增菜单', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(14, '修改菜单', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/menu', '修改菜单', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(15, '获取菜单详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/menu', '获取菜单详情', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(16, '删除菜单', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/menu', '删除菜单', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(17, '获取权限详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission', '获取权限详情', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(18, '获取角色列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/paginate', '获取角色列表', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(19, '新增角色', 'api', 'POST', '/dudu-admin-api/internal/admin/system/role', '新增角色', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(20, '修改角色', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/role', '修改角色', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(21, '获取角色详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role', '获取角色详情', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(22, '删除角色', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/role', '删除角色', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(23, '获取角色对应的权限', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/permission', '获取角色对应的权限', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(24, '配置角色权限', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/role/permission', '配置角色对应的权限', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(25, '获取所有角色列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/list', '获取所有角色列表', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(26, '获取用户列表', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/paginate', '获取用户列表', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(27, '新增用户', 'api', 'POST', '/dudu-admin-api/internal/admin/system/user', '新增用户', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(28, '修改用户', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user', '修改用户', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(29, '获取用户详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user', '获取用户详情', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(30, '删除用户', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user', '删除用户', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(31, '获取用户角色', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/role', '获取用户角色', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(32, '配置用户角色', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/role', '配置用户角色', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(33, '获取用户菜单', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/menus', '获取用户菜单', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(34, '获取用户信息', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/profile', '获取用户信息', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(35, '修改用户信息', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/profile', '修改用户信息', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(36, '获取所有权限', 'api', 'GET', '/dudu-admin-api/internal/admin/system/permission/list', '获取所有权限', 'sys-permission', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(37, '修改密码', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/password', '修改密码', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(38, '获取 TFA 状态', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/tfa/status', '获取 TFA 状态', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(39, '拉取2FA密钥/二维码', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/tfa/key', '开启 2FA 时拉取密钥/二维码', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(40, '启用 2FA', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/tfa/enable', '启用 2FA', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(41, '禁用 2FA', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/tfa/disable', '禁用 2FA', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(42, '修改账号', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/identifier', '修改账号', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(43, '获取 OAuth 登录地址', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/oauth/url', '获取 OAuth 登录地址', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(44, '操作记录', 'menu', NULL, NULL, '操作记录', 'sys-menu', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(45, '获取 Passkey 敏感操作验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/passkey/options', '获取 Passkey 敏感操作验证请求', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(46, '获取操作记录详情', 'api', 'GET', '/dudu-admin-api/internal/admin/system/record/detail', '获取操作记录详情', 'sys-operation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(47, '本地账号重认证', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth', '本地账号重认证', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(48, '获取 Passkey 登录验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/login/options', '获取 Passkey 登录验证请求', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(49, '删除用户全部 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user/passkeys', '删除用户全部 Passkey', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(50, '获取操作记录分页', 'api', 'GET', '/dudu-admin-api/internal/admin/system/record/paginate', '获取操作记录分页', 'sys-operation', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(51, '获取用户 Passkey', 'api', 'GET', '/dudu-admin-api/internal/admin/system/user/passkeys', '获取用户 Passkey', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(52, '确认第三方绑定', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/oauth/bind/confirm', '确认第三方绑定', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(53, '完成 Passkey 敏感操作验证', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/passkey/finish', '完成 Passkey 敏感操作验证', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(54, '完成 Passkey 注册', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/register/finish', '完成 Passkey 注册', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(55, '解绑第三方', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/oauth/unbind', '解绑第三方', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(56, '获取 Passkey 注册验证请求', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/register/options', '获取 Passkey 注册验证请求', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(57, '禁用用户 TFA', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/tfa/disable', '禁用用户 TFA', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(58, '重置用户密码', 'api', 'PUT', '/dudu-admin-api/internal/admin/system/user/password/reset', '重置用户密码', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(59, 'TOTP 验证敏感操作', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/totp', 'TOTP 验证敏感操作', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(60, '获取敏感操作验证方式', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/reauth/methods', '获取敏感操作验证方式', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(61, '密码验证敏感操作', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/reauth/password', '密码验证敏感操作', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(62, '获取当前用户 Passkey', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/passkeys', '获取当前用户 Passkey', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(63, '完成 Passkey 登录', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/passkey/login/finish', '完成 Passkey 登录', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(64, '删除用户 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/system/user/passkey', '删除用户 Passkey', 'sys-user', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(65, '重置密码（安全码）', 'api', 'PUT', '/dudu-admin-api/internal/admin/auth/password/reset', '重置密码（安全码）', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(66, '获取角色菜单权限树', 'api', 'GET', '/dudu-admin-api/internal/admin/system/role/permission/menu-tree', '获取角色菜单权限树', 'sys-role', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(67, '删除当前用户 Passkey', 'api', 'DELETE', '/dudu-admin-api/internal/admin/auth/passkey', '删除当前用户 Passkey', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(68, '获取已绑定第三方', 'api', 'GET', '/dudu-admin-api/internal/admin/auth/oauth/accounts', '获取已绑定第三方', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(69, '换取登录 Token', 'api', 'POST', '/dudu-admin-api/internal/admin/auth/token', '换取登录 Token', 'sys-base', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

INSERT INTO sys_menu (id, name, path, permission_id, parent_id, icon, sort, created_at, updated_at, deleted_at)
VALUES
(1, '首页', '/home', 1, 0, 'HomeFilled', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(2, '系统管理', '/system', 2, 0, 'Tools', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(3, '菜单管理', '/system/menu', 3, 2, 'Menu', 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(4, '权限管理', '/system/permission', 4, 2, 'fa-solid fa-lock', 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(5, '系统用户', '/system/user', 5, 2, 'fa-solid fa-users', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(6, '角色管理', '/system/role', 6, 2, 'fa-solid fa-user-shield', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL),
(7, '操作记录', '/system/operation', 44, 2, 'fa-solid fa-bars', 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

INSERT INTO sys_role_user (user_id, role_id)
VALUES
(1, 1),
(3, 1),
(3, 2);

INSERT INTO sys_permission_role (role_id, permission_id)
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

INSERT INTO auth_app (id, app_id, app_name, app_secret, redirect_uri, description, status, created_at, updated_at, deleted_at)
VALUES
(1, 'dudu-admin-api-bootstrap', 'dudu-admin-api bootstrap', 'PLEASE_CHANGE_ME_BOOTSTRAP_SECRET', 'http://127.0.0.1:3000', 'Bootstrap app for cold start. Replace secret before production.', 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, NULL);

SELECT setval('auth_app_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM auth_app;
SELECT setval('sys_role_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_role;
SELECT setval('sys_user_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_user;
SELECT setval('sys_permission_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_permission;
SELECT setval('sys_menu_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_menu;
SELECT setval('sys_user_identity_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_user_identity;
SELECT setval('sys_user_passkey_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_user_passkey;
SELECT setval('sys_operation_record_id_seq', COALESCE(MAX(id), 1), COALESCE(MAX(id) IS NOT NULL, FALSE)) FROM sys_operation_record;

COMMIT;
