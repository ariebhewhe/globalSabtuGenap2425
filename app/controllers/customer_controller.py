# controllers/user_controller.py
from fastapi import APIRouter, HTTPException, status 
import mysql.connector

# koneksi mysql cek folder dv
from ..db.database import mydb, cursor
# model Tabel cek folder model 
from ..model.CustomerModel import TBCustomer
# respon JSON cek folder utils
from ..utils.response import api_response

router = APIRouter()

# CREATE 
@router.post("/customer",status_code=status.HTTP_201_CREATED)

# Definisikan Customer model
def insert_customer(customer: TBCustomer):

    insert_query = """
    INSERT INTO customers (name, email, address)
    VALUES (%s, %s, %s)
    """
    values = (customer.name, customer.email, customer.address)

    try:
        cursor.execute(insert_query, values)
        mydb.commit()
    except mysql.connector.Error as err:
        raise HTTPException(status_code=400, detail=f"Error: {err}")

    return api_response(message="customer created successfully")

# READ All
@router.get("/customer",status_code=status.HTTP_302_FOUND)
def select_customer():
    select_query = "SELECT * FROM customers"
    cursor.execute(select_query)
    results = cursor.fetchall()
    return api_response(data=results, message="All customer retrieved")

# READ Single
@router.get("/customer/{customer_id}",status_code=status.HTTP_200_OK)
def get_customer_by_id(customer_id: int):
    select_query = "SELECT * FROM customers WHERE id = %s"
    cursor.execute(select_query, (customer_id,))
    result = cursor.fetchone()
    if result is None:
         raise HTTPException(status_code=404, detail="customer not found")
    return api_response(data=result, message="customer retrieved successfully")

# UPDATE 
@router.put("/customer/{customer_id}",status_code=status.HTTP_200_OK)
def update_customer(customer_id: int, customer: TBCustomer):

    update_query = """
    UPDATE customers
    SET name = %s, email = %s, address = %s
    WHERE id = %s
    """
    values = (customer.name,customer.email, customer.address, customer_id)

    cursor.execute(update_query, values)
    mydb.commit()
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="customer not found")
    return api_response(message="customer updated successfully")

# DELETE user
@router.delete("/customer/{customer_id}",status_code=status.HTTP_200_OK)
def delete_user(customer_id: int):
    delete_query = "DELETE FROM users WHERE id = %s"
    cursor.execute(delete_query, (customer_id,))
    mydb.commit()
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="customer not found")
    return api_response(message="customer deleted successfully")