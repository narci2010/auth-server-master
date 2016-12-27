--
-- Turn off autocommit and start a transaction so that we can use the temp tables
--

SET AUTOCOMMIT FALSE;

START TRANSACTION;

--
-- Insert client information into the temporary tables. To add clients to the HSQL database, edit things here.
-- 

INSERT INTO client_details_TEMP (client_id, client_secret, client_name, dynamically_registered, refresh_token_validity_seconds, access_token_validity_seconds, id_token_validity_seconds, allow_introspection) VALUES
	('client', 'secret', 'Test Client', false, null, 3600, 600, true),
        ('growth_chart', '', 'growth chart', false, null, 3600, 600, true),
        ('fhir_starter', '', 'fhir starter', false, null, 3600, 600, true);

INSERT INTO client_scope_TEMP (owner_id, scope) VALUES
	('client', 'openid'),
	('client', 'profile'),
	('client', 'email'),
	('client', 'address'),
	('client', 'phone'),
	('client', 'fhir-complete'),
	('client', 'search'),
	('client', 'summary'),
	('client', 'offline_access'),
        ('client', 'smart/orchestrate_launch'),
        ('client', 'user/*.*'),
        ('growth_chart', 'openid'),
	('growth_chart', 'profile'),
	('growth_chart', 'email'),
	('growth_chart', 'address'),
	('growth_chart', 'phone'),
	('growth_chart', 'fhir-complete'),
	('growth_chart', 'search'),
	('growth_chart', 'summary'),
	('growth_chart', 'offline_access'),
        ('growth_chart', 'patient/*.read'),
        ('growth_chart', 'launch/patient'),
        ('growth_chart', 'launch'),
        ('fhir_starter', 'smart/orchestrate_launch'),
        ('fhir_starter', 'user/*.*');

INSERT INTO client_redirect_uri_TEMP (owner_id, redirect_uri) VALUES
	('client', 'http://localhost/'),
	('client', 'http://localhost:8080/'),
        ('fhir_starter', 'http://localhost:8080/'),
        ('growth_chart', 'http://localhost:8080/'),
	('client', 'http://ec2-35-164-199-202.us-west-2.compute.amazonaws.com:8080/'),
        ('fhir_starter', 'http://ec2-35-164-199-202.us-west-2.compute.amazonaws.com:8080/'),
        ('growth_chart', 'http://ec2-35-164-199-202.us-west-2.compute.amazonaws.com:8080/');
	
INSERT INTO client_grant_type_TEMP (owner_id, grant_type) VALUES
	('client', 'authorization_code'),
	('client', 'urn:ietf:params:oauth:grant_type:redelegate'),
	('client', 'implicit'),
	('client', 'refresh_token'),
        ('growth_chart', 'authorization_code'),
	('growth_chart', 'urn:ietf:params:oauth:grant_type:redelegate'),
	('growth_chart', 'implicit'),
	('growth_chart', 'refresh_token'),
        ('fhir_starter', 'authorization_code'),
	('fhir_starter', 'urn:ietf:params:oauth:grant_type:redelegate'),
	('fhir_starter', 'implicit'),
	('fhir_starter', 'refresh_token');
	
--
-- Merge the temporary clients safely into the database. This is a two-step process to keep clients from being created on every startup with a persistent store.
--

MERGE INTO client_details 
  USING (SELECT client_id, client_secret, client_name, dynamically_registered, refresh_token_validity_seconds, access_token_validity_seconds, id_token_validity_seconds, allow_introspection FROM client_details_TEMP) AS vals(client_id, client_secret, client_name, dynamically_registered, refresh_token_validity_seconds, access_token_validity_seconds, id_token_validity_seconds, allow_introspection)
  ON vals.client_id = client_details.client_id
  WHEN NOT MATCHED THEN 
    INSERT (client_id, client_secret, client_name, dynamically_registered, refresh_token_validity_seconds, access_token_validity_seconds, id_token_validity_seconds, allow_introspection) VALUES(client_id, client_secret, client_name, dynamically_registered, refresh_token_validity_seconds, access_token_validity_seconds, id_token_validity_seconds, allow_introspection);

MERGE INTO client_scope 
  USING (SELECT id, scope FROM client_scope_TEMP, client_details WHERE client_details.client_id = client_scope_TEMP.owner_id) AS vals(id, scope)
  ON vals.id = client_scope.owner_id AND vals.scope = client_scope.scope
  WHEN NOT MATCHED THEN 
    INSERT (owner_id, scope) values (vals.id, vals.scope);

MERGE INTO client_redirect_uri 
  USING (SELECT id, redirect_uri FROM client_redirect_uri_TEMP, client_details WHERE client_details.client_id = client_redirect_uri_TEMP.owner_id) AS vals(id, redirect_uri)
  ON vals.id = client_redirect_uri.owner_id AND vals.redirect_uri = client_redirect_uri.redirect_uri
  WHEN NOT MATCHED THEN 
    INSERT (owner_id, redirect_uri) values (vals.id, vals.redirect_uri);

MERGE INTO client_grant_type 
  USING (SELECT id, grant_type FROM client_grant_type_TEMP, client_details WHERE client_details.client_id = client_grant_type_TEMP.owner_id) AS vals(id, grant_type)
  ON vals.id = client_grant_type.owner_id AND vals.grant_type = client_grant_type.grant_type
  WHEN NOT MATCHED THEN 
    INSERT (owner_id, grant_type) values (vals.id, vals.grant_type);
    
-- 
-- Close the transaction and turn autocommit back on
-- 
    
COMMIT;

SET AUTOCOMMIT TRUE;

