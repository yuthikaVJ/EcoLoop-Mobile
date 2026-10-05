import psycopg2
conn = psycopg2.connect(dbname='ecoloop', user='postgres', password='Geemal@2003', host='localhost', port=5432)
cur = conn.cursor()
cur.execute('SELECT "Email" FROM "Businesses" LIMIT 1;')
print(cur.fetchone()[0])
