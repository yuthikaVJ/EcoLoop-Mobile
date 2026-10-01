import psycopg2

conn = psycopg2.connect(
    dbname='ecoloop', 
    user='postgres', 
    password='Geemal@2003', 
    host='localhost', 
    port=5432
)
conn.autocommit = True
cur = conn.cursor()

print('Truncating tables...')
cur.execute('TRUNCATE TABLE "Products", "MaterialListings" CASCADE;')
print('Successfully deleted all products and materials!')

cur.close()
conn.close()
