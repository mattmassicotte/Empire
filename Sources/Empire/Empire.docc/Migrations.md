# Migrations

Manage changes to your data models over time.

## Overview

Types that conform to ``IndexKeyRecord``, either via the macro or manually, **define** the on-disk serialization format. Any changes to these types will invalidate the data within the storage. This is detected using the `fieldsVersion` and `keyPrefix` properties, and 
fixing it requires migrations. These are run incrementally as mismatches are detected on load.
