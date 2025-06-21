# controllers/user_controller.py
from fastapi import APIRouter, HTTPException, status 
import hashlib
import mysql.connector

# koneksi mysql cek folder dv
from ..db.database import mydb, cursor
# model Tabel cek folder model 
from ..model.UserModel import TBUser
# respon JSON cek folder utils
from ..utils.response import api_response

router = APIRouter()

# CREATE user
@router.post("/users",status_code=status.HTTP_201_CREATED)
def insert_user(user: TBUser):
    # Hash the password using SHA-256
    hashed_password = hashlib.sha256(user.password.encode()).hexdigest()

    insert_query = """
    INSERT INTO users (username, password, email)
    VALUES (%s, %s, %s)
    """
    values = (user.username, hashed_password, user.email)

    try:
        cursor.execute(insert_query, values)
        mydb.commit()
    except mysql.connector.Error as err:
        raise HTTPException(status_code=400, detail=f"Error: {err}")

    return api_response(message="user created successfully")

# READ All user 
@router.get("/users",status_code=status.HTTP_302_FOUND)
def select_users():
    select_query = "SELECT * FROM users"
    cursor.execute(select_query)
    results = cursor.fetchall()
    return api_response(data=results, message="All user retrieved")

# READ Single user
@router.get("/users/{user_id}",status_code=status.HTTP_200_OK)
def get_user_by_id(user_id: int):
    select_query = "SELECT * FROM users WHERE id = %s"
    cursor.execute(select_query, (user_id,))
    result = cursor.fetchone()
    if result is None:
         raise HTTPException(status_code=404, detail="User not found")
    return api_response(data=result, message="User retrieved successfully")

# UPDATE user 
@router.put("/users/{user_id}",status_code=status.HTTP_200_OK)
def update_user(user_id: int, user: TBUser):
    # Hash the password using SHA-256
    hashed_password = hashlib.sha256(user.password.encode()).hexdigest()

    update_query = """
    UPDATE users
    SET username = %s, password = %s, email = %s
    WHERE id = %s
    """
    values = (user.username, hashed_password, user.email, user_id)

    cursor.execute(update_query, values)
    mydb.commit()
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return api_response(message="user updated successfully")

# DELETE user
@router.delete("/users/{user_id}",status_code=status.HTTP_200_OK)
def delete_user(user_id: int):
    delete_query = "DELETE FROM users WHERE id = %s"
    cursor.execute(delete_query, (user_id,))
    mydb.commit()
    if cursor.rowcount == 0:
        raise HTTPException(status_code=404, detail="User not found")
    return api_response(message="User deleted successfully")