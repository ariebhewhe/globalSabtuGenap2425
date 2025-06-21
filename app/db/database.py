import mysql.connector

# Connect to the database
mydb = mysql.connector.connect(
    host="localhost",
    user="arybw",
    password="arybw",
    database="latihan_fastapi"
)

# Create a cursor object
cursor = mydb.cursor()