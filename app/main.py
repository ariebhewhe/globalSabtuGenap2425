# main.py
from fastapi import FastAPI
# controller cek folder controller 
from .controllers.user_controller import router as user_router
from .controllers.customer_controller import router as customer_router

tags_metadata = [
    {"name": "Pengguna","description": "Crud untuk pengguna / user. "},
    {"name":"Customers","description": "Crud untuk pengguna Customers. "},
    {"name": "Mahasiswa","description": "CRUD data mahasiswa."}
]

description = """
🚀ABWarsito API Sarana latihan Mobile Programming.
Aplikasi webservice ini berbasi MVC sederhana sehingga memudahkan kalian untuk memodifikasi
🚀

Instalasi: 
* Python 3.10+ :
    * Install: FastAPI, pydantic, mysql.connector, hashlib, Uvicorn
        pip install fastapi uvicorn pydantic mysql-connector-python,hashlib
* Database : MYSQL ( <a href='https://laragon.org/download/' > server Laragon </a> )  

### Tabel :
* **<a href="/users">Users</a>** : create, Read, Update, Delete, Search (_implemented_)
* **<a href="/customer">customer</a>** : create, Read, Update, Delete, Search (_implemented_)

"""

app = FastAPI(
    title="ABWarsito API",
    description=description,
    version="0.0.1",
    contact={
        "name": "AbWarsito",
        "url": "http://abwarsito.my.id/",
        "email": "ariebhewhe@gmail.com",
    },
    license_info={
        "name": "Apache 2.0",
        "identifier": "MIT",
    },
    swagger_ui_parameters={"defaultModelsExpandDepth": -1}
)

# route user
# contoh : app.include_router(customer_router, prefix="/api", tags=["Customers"])
app.include_router(user_router, tags=["Pengguna"])
app.include_router(customer_router, tags=["Customers"])

@app.get("/")
def root():
    return {"message": "Selamat data di latihan webservice Mobile Prograaming"}