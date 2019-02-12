# Logical replication

All necessary documentation can be found on [pglogical official webpage](https://www.2ndquadrant.com/en/resources/pglogical/pglogical-docs/).

[Docker images repository](https://github.com/Nebo15/alpine-postgre/tree/pglogical).

## Requirements

1. The pglogical extension must be installed on both provider and subscriber. You must run `CREATE EXTENSION pglogical` on both.
2. Tables on the provider and subscriber must have the same names and be in the same schema.
3. Tables on the provider and subscriber must have the same columns, with the same data types in each column. CHECK constraints, NOT NULL constraints, etc must be the same or weaker (more permissive) on the subscriber than the provider.
4. You need to use db passwords generated in paragraph 1 of the README.md file, to insert it into `databasepassword` values in commands bellow.

Currently there are four "provider" databases:

* `PRM`,
* `MPI`,
* `OPS`,
* `UADDRESSES`.

And 2 "subscriber" databases:

* `REPORT`
* `FRAUD`

## How to configure databases providers (if needed), otherwise look at 'Configuring Logical replication'?

For new pglogical deployment:

1. Run script on each database pod:

    ```
    kubectl exec db-0 -it --namespace ops --context ehealth-dev bin/bash ./docker-entrypoint-initdb.d/replication.sh
    ```

2. Delete pod

3. Execute sql request:

    ```sql
    CREATE EXTENSION pglogical;
    ```


## List of replicated tables for REPORT database

### PRM

| Table                       | Fields                                                                           |
| -------------               | :-------------                                                                   |
| `divisions`                 |                                                                                  |
| `division_addresses`        |                                                                                  |
| `employees`                 | `id,positions,status,employee_type,inserted_by,updated_by,start_date,end_date,status_reason,legal_entity_id,division_id,party_id,inserted_at,updated_at,is_active`                                         |
| `medical_service_providers` |                                                                                  |
| `parties`                   | `id,first_name,last_name,second_name`                                     |
| `party_users`               |                                                                                  |
| `medications`               |                                                                                  |
| `medical_programs`          |                                                                                  |
| `legal_entities`            | `id,name,short_name,public_name,type,edrpou,addresses,phones,email,inserted_at,inserted_by,updated_at,updated_by,is_active,kveds,status,owner_property_type,legal_form,created_by_mis_client_id,nhs_verified,mis_verified` |
| `innms`                     |                                                                                  |
| `ingredients`               |                                                                                  |

### UADRESSES

| Table             |
| -----------       |
| `regions`         |
| `districts`       |
| `settlements`     |
| `streets`         |
| `streets_aliases` |


### MPI


| Table       | Fields                                                      |
| ----------- | :----------                                                 |
| `persons`   | `id,birth_date,death_date,addresses,inserted_at,updated_at` |


### OPS


| Table                             | Fields                                                                                                                                                                               |
| -----------                       | :----------                                                                                                                                                                          |
| `declarations`                    | `id,employee_id,person_id,start_date,end_date,status,signed_at,created_by,updated_by,is_active,scope,division_id,legal_entity_id,inserted_at,updated_at,declaration_request_id,seed` |
| `medication_requests`             |                                                                                                                                                                                      |
| `medication_dispenses`            |                                                                                                                                                                                      |
| `medication_dispense_details`     |                                                                                                                                                                                      |
| `medication_dispense_status_hstr` |                                                                                                                                                                                      |
| `medication_requests_status_hstr` |                                                                                                                                                                                      |
| `declarations_status_hstr`        |                                                                                                                                                                                      |
| `contracts` |               |
| `contract_divisions`        |
| `contract_employees`        |

## List of replicated tables for FRAUD database

### PRM

| Table            | Fields                                                                                                                                                                                                                                            |
| -------------    | :---------                                                                                                                                                                                                                                        |
| `legal_entities` | `id,name,short_name,public_name,status,type,owner_property_type,legal_form,edrpou,kveds,addresses,phones,email,is_active,inserted_by,updated_by,inserted_at,updated_at,capitation_contract_id,created_by_mis_client_id,mis_verified,nhs_verified` |
| `divisions`      | `id,external_id,name,type, mountain_group,addresses,phones,email,inserted_at,updated_at,legal_entity_id,location,status,is_active` |
| `division_addresses` |                                                                                                      |
| `employees`      | `id,position,status,employee_type,is_active,inserted_by,updated_by,start_date,end_date,legal_entity_id,division_id,party_id,inserted_at,updated_at,status_reason,additional_info`|
| `parties`        | `id,gender,first_name,last_name,second_name,no_tax_id,inserted_by,updated_by,inserted_at,updated_at`                                      |
| `party_users`    |                                                                                                          |
| `audit_log`      |                                                                                                          |

### MPI

| Table         | Fields                                                                                                                                                                                                                                                                                                                               |
| ------        | :-----                                                                                                                                                                                                                                                                                                                               |
| persons       | `id,first_name,last_name,second_name,birth_date,birth_country,birth_settlement,gender,email,tax_id,national_id,death_date,is_active,secret,status,patient_signed,process_disclosure_data_consent,documents,addresses,phones,emergency_contact,confidant_person,authentication_methods,inserted_by,updated_by,inserted_at,updated_at` |
| audit_log_mpi |                                                                                                                                                                                                                                                                                                                                      |

### OPS

| Table                    | Fields                                                                                                                                                                          |
| -----                    | :-----                                                                                                                                                                          |
| declarations             | `id,employee_id,person_id,start_date,end_date,status,signed_at,created_by,updated_by,is_active,scope,division_id,legal_entity_id,declaration_request_id,inserted_at,updated_at` |
| declarations_status_hstr |                                                                                                                                                                                 |

### IL

| Table                | Fields                                                                                                 |
| -----                | :-----                                                                                                 |
| declaration_requests | `id,declaration_id,authentication_method_current,status,inserted_by,updated_by,inserted_at,updated_at` |
| employee_requests    | `id,status,employee_id,inserted_at,updated_at`                                                         |
| dictionaries         |                                                                                                        |

### Configuring Logical replication
### 1. Setting up "subscribers" in REPORT and FRAUD databases

To configure "subscriber" on REPORT or FRAUD databases, execute the following SQL scripts:

* Drop the "node" if necessary:

    ```sql
    SELECT pglogical.drop_node('subscriber');
    ```

* Create "subscriber" in REPORT node:

    ```sql
    SELECT pglogical.create_node(node_name := 'subscriber', dsn := 'host=db-svc.reports.svc.cluster.local port=5432 dbname=report user=databaseuser password=databasepassword');
    ```

* Create "subscriber" in FRAUD node:

    ```sql
    SELECT pglogical.create_node(node_name := 'subscriber', dsn := 'host=db-svc.fraud.svc.cluster.local port=5432 dbname=fraud user=databaseuser password=databasepassword');
    ```

### 2. Configuring PRM database

To configure "provider" on PRM database, execute the following SQL scripts:

* Drop existing "provider node" if necessary:

    ```sql
    SELECT pglogical.drop_node('provider_prm');
    ```

* Create "provider node":

    ```sql
    SELECT pglogical.create_node(node_name := 'provider_prm', dsn := 'host=db-svc.prm.svc.cluster.local port=5432 dbname=prm user=databaseuser password=databasepassword');
    ```

* Add tables to `default` replication set:

    ```sql
    SELECT pglogical.replication_set_add_table('default', 'divisions', 'true');
    SELECT pglogical.replication_set_add_table('default', 'division_addresses', 'true');
    SELECT pglogical.replication_set_add_table('default', 'employees', 'true', columns := '{id,position,status,employee_type,inserted_by,updated_by,start_date,end_date,status_reason,legal_entity_id,division_id,party_id,inserted_at,updated_at,is_active,speciality}');
    SELECT pglogical.replication_set_add_table('default', 'medical_service_providers', 'true') ;
    SELECT pglogical.replication_set_add_table('default', 'parties', 'true', columns := '{id,first_name,last_name,second_name,educations,qualifications,specialities,science_degree,declaration_limit,inserted_at,updated_at,about_myself,working_experience}');
    SELECT pglogical.replication_set_add_table('default', 'party_users', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medications', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medical_programs', 'true');
    SELECT pglogical.replication_set_add_table('default', 'legal_entities', 'true', columns := '{id,name,short_name,public_name,type,edrpou,addresses,phones,email,inserted_at,inserted_by,updated_at,updated_by,is_active,kveds,status,owner_property_type,legal_form,created_by_mis_client_id,nhs_verified,mis_verified}');
    SELECT pglogical.replication_set_add_table('default', 'innms', 'true');
    SELECT pglogical.replication_set_add_table('default', 'ingredients', 'true');
    ```

* Create `fraud` replication set:

    ```sql
    SELECT pglogical.create_replication_set('fraud');
    ```

* Add tables to `fraud` replication set:

    ```sql
    SELECT pglogical.replication_set_add_table('fraud', 'legal_entities', 'true', columns := '{id,name,short_name,public_name,status,type,owner_property_type,legal_form,edrpou,kveds,addresses,phones,email,is_active,inserted_by,updated_by,inserted_at,updated_at,capitation_contract_id,created_by_mis_client_id,mis_verified,nhs_verified}');
    SELECT pglogical.replication_set_add_table('fraud', 'divisions', 'true', columns := '{id,external_id,name,type, mountain_group,addresses,phones,email,inserted_at,updated_at,legal_entity_id,location,status,is_active}');
    SELECT pglogical.replication_set_add_table('fraud', 'division_addresses', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'employees', 'true', columns := '{id,position,status,employee_type,is_active,inserted_by,updated_by,start_date,end_date,legal_entity_id,division_id,party_id,inserted_at,updated_at,status_reason,speciality}');
    SELECT pglogical.replication_set_add_table('fraud', 'parties', 'true', columns := '{id,first_name,last_name,second_name,gender,no_tax_id,inserted_by,updated_by,inserted_at,updated_at,educations,qualifications,specialities,science_degree}');
    SELECT pglogical.replication_set_add_table('fraud', 'party_users', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'audit_log', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'black_list_users', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'innms', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medical_programs', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medications', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'program_medications', 'true');
    ```

* Create subscription at REPORT database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_prm', provider_dsn := 'host=db-svc.prm.svc.cluster.local port=5432 dbname=prm user=databaseuser password=databasepassword');
    ```

* Create subscription at FRAUD database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_prm', provider_dsn := 'host=db-svc.prm.svc.cluster.local  port=5432 dbname=prm user=databaseuser password=databasepassword', replication_sets := '{fraud}');
    ```

### 3. Configuring UADDRESSES database

To configure "provider" on UADDRESSES database, execute the following SQL scripts:

* Drop existing "provider node" if necessary:

    ```sql
    SELECT pglogical.drop_node('provider_prm');
    ```

* Create "provider node":

    ```sql
    SELECT pglogical.create_node(node_name := 'provider-uaddresses', dsn := 'host=db-svc.uaddresses.svc.cluster.local port=5432 dbname=uaddresses user=databaseuser password=databasepassword');
    ```

* Add tables to replication set:

    ```sql
    SELECT pglogical.replication_set_add_table('default', 'regions', 'true');
    SELECT pglogical.replication_set_add_table('default', 'districts', 'true');
    SELECT pglogical.replication_set_add_table('default', 'settlements', 'true');
    SELECT pglogical.replication_set_add_table('default', 'streets', 'true');
    SELECT pglogical.replication_set_add_table('default', 'streets_aliases', 'true');
    ```

* Create subscription at REPORT database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_uaddresses', provider_dsn := 'host=db-svc.uaddresses.svc.cluster.local  port=5432 dbname=uaddresses user=databaseuser password=databasepassword');
    ```

### 4. Configuring MPI database

To configure "provider" on MPI database, execute the following SQL scripts:

* Drop existing "provider node" if necessary:

    ```sql
    SELECT pglogical.drop_node('provider_mpi');
    ```

* Create "provider node":

    ```sql
    SELECT pglogical.create_node(node_name := 'provider_mpi', dsn := 'host=db-svc.mpi.svc.cluster.local port=5432 dbname=mpi user=databaseuser password=databasepassword');
    ```

* Create `fraud` replication set:

    ```sql
    SELECT pglogical.create_replication_set('fraud');
    ```

* Add tables to replication set:

    ```sql
    SELECT pglogical.replication_set_add_table('default', 'persons', 'true', columns := '{id,birth_date,death_date,addresses,inserted_at,updated_at}');
    ```

* Add tables to `fraud` replication set:

   ```sql
   SELECT pglogical.replication_set_add_table('fraud', 'persons', 'true', columns := '{id,birth_date,birth_country,gender,email,death_date,is_active,status,patient_signed,process_disclosure_data_consent,phones,authentication_methods,inserted_by,updated_by,inserted_at,updated_at}');
   SELECT pglogical.replication_set_add_table('fraud', 'audit_log_mpi', 'true');
   ```

* Create subscription at REPORT database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_mpi', provider_dsn := 'host=db-svc.mpi.svc.cluster.local  port=5432 dbname=mpi user=databaseuser password=databasepassword');
    ```

* Create subscription at FRAUD database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_mpi', provider_dsn := 'host=db-svc.mpi.svc.cluster.local  port=5432 dbname=mpi user=databaseuser password=databasepassword', replication_sets := '{fraud}');
    ```

### 5. Configuring OPS database

To configure "provider" on OPS database, execute the following SQL scripts:

* Drop existing "provider node" if necessary:

    ```sql
    SELECT pglogical.drop_node('provider_ops');
    ```

* Create "provider node":

    ```sql
    SELECT pglogical.create_node(node_name := 'provider_ops',dsn := 'host=db-svc.ops.svc.cluster.local port=5432  dbname=ops user=databaseuser password=databasepassword');
    ```

* Reset `declaration_count` on `report` db before creating/recreating OPS reports replica:

    ```sql
    UPDATE parties SET declaration_count = NULL;
    ```

* In case declaration_count is wrong, manually update that column:

```sql
    UPDATE parties AS p
    SET declaration_count = a.count
    FROM (
        SELECT p.id, count(1) FROM parties p
        LEFT JOIN employees e ON p.id = e.party_id
        LEFT JOIN declarations d ON d.employee_id = e.id
        WHERE d.status = 'active' GROUP BY p.id
    ) AS a WHERE p.id = a.id;
```

* Create `fraud` replication set:

    ```sql
    SELECT pglogical.create_replication_set('fraud');
    ```

* Add tables to replication set:

    ```sql
    SELECT pglogical.replication_set_add_table('default', 'declarations', 'true', columns := '{id,employee_id,person_id,start_date,end_date,status,signed_at,created_by,updated_by,is_active,scope,division_id,legal_entity_id,inserted_at,updated_at,declaration_request_id,seed}');
    SELECT pglogical.replication_set_add_table('default', 'medication_requests', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medication_dispenses', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medication_dispense_details', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medication_dispense_status_hstr', 'true');
    SELECT pglogical.replication_set_add_table('default', 'medication_requests_status_hstr', 'true');
    SELECT pglogical.replication_set_add_table('default', 'declarations_status_hstr', 'true');
    SELECT pglogical.replication_set_add_table('default', 'contracts', 'true');
    SELECT pglogical.replication_set_add_table('default', 'contract_divisions', 'true');
    SELECT pglogical.replication_set_add_table('default', 'contract_employees', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medication_dispenses', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medication_dispense_details', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medication_dispense_status_hstr', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medication_requests', 'true');
    SELECT pglogical.replication_set_add_table('fraud', 'medication_requests_status_hstr', 'true');
    ```

* Add tables to `fraud` replication set:

   ```sql
   SELECT pglogical.replication_set_add_table('fraud', 'declarations', 'true', columns := '{id,employee_id,person_id,start_date,end_date,status,signed_at,created_by,updated_by,is_active,scope,division_id,legal_entity_id,declaration_request_id,inserted_at,updated_at}');
   SELECT pglogical.replication_set_add_table('fraud', 'declarations_status_hstr', 'true');
   ```

* Create subscription at REPORT database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_ops', provider_dsn := 'host=db-svc.ops.svc.cluster.local  port=5432 dbname=ops user=databaseuser password=databasepassword');
    ```

* Create subscription at FRAUD database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_ops', provider_dsn := 'host=db-svc.ops.svc.cluster.local  port=5432 dbname=ops user=databaseuser password=databasepassword', replication_sets := '{fraud}');
    ```

### 6. Configuring IL database

To configure "provider" on IL database, execute the following SQL scripts:

* Drop existing "provider node" if necessary:

    ```sql
    SELECT pglogical.drop_node('provider_il');
    ```

* Create "provider node":

    ```sql
    SELECT pglogical.create_node(node_name := 'provider_il',dsn := 'host=db-svc.il.svc.cluster.local port=5432  dbname=il user=databaseuser password=databasepassword');
    ```

* Create `fraud` replication set:

    ```sql
    SELECT pglogical.create_replication_set('fraud');
    ```

* Add tables to `fraud` replication set:

   ```sql
   SELECT pglogical.replication_set_add_table('fraud', 'declaration_requests', 'true', columns := '{id,declaration_id,authentication_method_current,status,inserted_by,updated_by,inserted_at,updated_at}');
   SELECT pglogical.replication_set_add_table('fraud', 'employee_requests', 'true', columns := '{id,status,employee_id,inserted_at,updated_at}');
   SELECT pglogical.replication_set_add_table('fraud', 'dictionaries', 'true');
   SELECT pglogical.replication_set_add_table('fraud', 'medication_request_requests', 'true');
   ```

* Create subscription at FRAUD database:

    ```sql
    SELECT pglogical.create_subscription(subscription_name := 'subscription_il', provider_dsn := 'host=db-svc.il.svc.cluster.local  port=5432 dbname=il user=databaseuser password=databasepassword', replication_sets := '{fraud}');
    ```

## Useful scripts execute on "subscriber"

* Check replication status:

    ```sql
    SELECT * FROM pglogical.show_subscription_status();
    ```

* Check replication table status:

    ```sql
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','divisions') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','division_addresses') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','employees') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','legal_entities') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','medical_service_providers') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','parties') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_prm','party_users') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_uaddresses', 'regions') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_uaddresses', 'districts') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_uaddresses', 'settlements') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_uaddresses', 'streets') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_uaddresses', 'streets_aliases') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'declarations') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'medication_requests') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'medication_dispenses') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'medication_dispense_details') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'medication_dispense_status_hstr') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'medication_requests_status_hstr') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_ops', 'declarations_status_hstr') UNION
    SELECT * FROM pglogical.show_subscription_table('subscription_mpi', 'persons');
    ```

* Resynchronize tables if necessary. The tables will be truncated!

    PRM:

    ```sql
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'divisions');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'division_addresses');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'employees');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'legal_entities');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'medical_service_providers');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'parties');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_prm', 'party_users');
    ```

    UADDRESSES:

    ```sql
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_uaddresses', 'regions');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_uaddresses', 'districts');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_uaddresses', 'settlements');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_uaddresses', 'streets');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_uaddresses', 'streets_aliases');
    ```

    MPI:

    ```sql
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_mpi', 'persons');
    ```

    OPS:

    ```sql
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'declarations');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'medication_requests');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'medication_dispenses');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'medication_dispense_details');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'medication_dispense_status_hstr');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'medication_requests_status_hstr');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'declarations_status_hstr');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'contracts');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'contract_divisions');
    SELECT pglogical.alter_subscription_resynchronize_table('subscription_ops', 'contract_employees');
    ```
