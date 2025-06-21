from pydantic import BaseModel

class TBCustomer(BaseModel):
    name: str
    email: str
    address: str

