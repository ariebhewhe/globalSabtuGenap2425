from pydantic import BaseModel

class TBUser(BaseModel):
    username: str
    password: str
    email: str

