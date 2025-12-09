const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const { mongoImport } = require('./../mongo-func.js');
const bcryptjs = require('bcryptjs');
const crypto = require('crypto');
const dayjs = require('dayjs');

/** @param {import('mongodb').Db} db */
exports.up = async function (db) {
	console.log('🚀 Creating...');
	await db.createCollection('core_user');
	await db.createCollection('core_roles');
	await db.createCollection('core_setting');
	await db.createCollection('core_files_manage');
	await db.createCollection('sdform_manage');
	await db.createCollection('module_api');
	await db.createCollection('module_notify');
	await db.createCollection('module_packages');
	await db.createCollection('module_report');
	await db.createCollection('module_sql');
	await db.createCollection('log_cache');

	await db.collection('core_user').createIndex({ username: 1 }, { unique: true, name: 'username_1' });
	await db.collection('core_user').createIndex({ email: 1 }, { unique: true, name: 'email_1' });
	await db.collection('core_user').createIndex({ roles: 1 }, { name: 'roles_1' });
	await db.collection('core_user').createIndex({ 'profile.fname': 1, 'profile.lname': 1 }, { name: 'profile_fname_lname_1' });
	await db.collection('core_user').createIndex({ 'site.code': 1 }, { name: 'site_code_1' });
	await db.collection('core_user').createIndex({ 'unit.code': 1 }, { name: 'unit_code_1' });

	await db.collection('core_roles').createIndex({ role_name: 1 }, { name: 'rolename_1' });
	await db.collection('core_setting').createIndex({ opts_code: 1 }, { name: 'opts_code_1' });
	await db.collection('core_setting').createIndex({ opts_label: 1 }, { name: 'opts_label_1' });
	await db.collection('core_setting').createIndex({ opts_group: 1 }, { name: 'opts_group_1' });
	await db.collection('module_packages').createIndex({ app_code: 1 }, { name: 'app_code_1' });
	await db.collection('module_packages').createIndex({ app_name: 1 }, { name: 'app_name_1' });
	await db.collection('module_api').createIndex({ api_name: 1 }, { name: 'api_name_1' });
	await db.collection('module_sql').createIndex({ sql_name: 1 }, { name: 'sql_name_1' });
	await db.collection('module_report').createIndex({ pdf_name: 1 }, { name: 'pdf_name_1' });
	await db.collection('module_notify').createIndex({ mode: 1 }, { name: 'mode_1' });
	await db.collection('module_notify').createIndex({ title: 1 }, { name: 'title_1' });
	await db.collection('log_cache').createIndex({ key: 1 }, { unique: true, name: 'key_1' });

	await db.collection('sdform_manage').createIndex({ form_name: 1 }, { name: 'form_name_1' });
	await db.collection('sdform_manage').createIndex({ form_table: 1 }, { name: 'form_table_1' });
	await db.collection('sdform_manage').createIndex({ form_tag: 1 }, { name: 'form_tag_1' });
	await db.collection('sdform_manage').createIndex({ form_category: 1 }, { name: 'form_category_1' });
	await db.collection('sdform_manage').createIndex({ form_license: 1 }, { name: 'form_license_1' });
	await db.collection('sdform_manage').createIndex({ form_type: 1 }, { name: 'form_type_1' });

	try {
		let initUser = {
			username: 'admin',
			email: 'admin@initSDK.com',
			password_hash: await bcryptjs.hash('123456', 7),
			auth_key: crypto.randomUUID(),
			password_reset_token: null,
			flags: 1, //-1=block 0=new user not active 1= active
			confirmed_at: null,
			blocked_at: null,
			confirmed_email: false,
			last_login_at: null,
			profile: {
				fname: 'SuperAdmin',
				lname: 'InitAPI',
				tel: null,
				avatar: [],
				position: {
					code: '00',
					name: 'none',
				},
				certificate_code: '00',
				person_code: '00',
			},
			site: { code: '00000', name: 'Center' },
			unit: { code: '00000', name: 'Center' },
			notify_last_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			updated_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			created_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			updated_by: null,
			created_by: null,
			roles: ['user', 'admin', 'manager', 'auth', 'super'],
		};

		await db.collection('core_user').insertOne(initUser);
		console.log('✅ Initial user admin inserted successfully!');

		let initGuest = {
			username: 'guest',
			email: 'guest@initSDK.com',
			password_hash: await bcryptjs.hash('123456', 7),
			auth_key: crypto.randomUUID(),
			password_reset_token: null,
			flags: 1, //-1=block 0=new user not active 1= active
			confirmed_at: null,
			blocked_at: null,
			confirmed_email: false,
			last_login_at: null,
			profile: {
				fname: 'guest',
				lname: 'visit',
				tel: null,
				avatar: [],
				position: {
					code: '00',
					name: 'none',
				},
				certificate_code: '00',
				person_code: '00',
			},
			site: { code: '00000', name: 'Center' },
			unit: { code: '00000', name: 'Center' },
			notify_last_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			updated_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			created_at: dayjs().format('YYYY-MM-DD HH:mm:ss'),
			updated_by: null,
			created_by: null,
			roles: ['user'],
		};

		await db.collection('core_user').insertOne(initGuest);
		console.log('✅ Initial user guest inserted successfully!');
	} catch (err) {
		if (err.code === 11000) {
			console.warn('❌ User already exists, skipping insert.');
		} else {
			console.error('❌ Initial user failed:', err);
		}
	}

	try {
		const cmdSetting = mongoImport('core_setting', 'core_setting.json');
		await execAsync(cmdSetting);
	} catch (err) {
		console.error('❌ Import failed:', err);
	}
};

/** @param {import('mongodb').Db} db */
exports.down = async function (db) {
	console.log('🚀 Rollback...');
	await db.collection('core_user').drop();
	await db.collection('core_roles').drop();
	await db.collection('core_setting').drop();
	await db.collection('core_files_manage').drop();
	await db.collection('sdform_manage').drop();
	await db.collection('module_api').drop();
	await db.collection('module_notify').drop();
	await db.collection('module_packages').drop();
	await db.collection('module_report').drop();
	await db.collection('module_sql').drop();
	await db.collection('log_cache').drop();
};
