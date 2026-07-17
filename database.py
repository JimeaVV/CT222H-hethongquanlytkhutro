from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
 
 
SERVER_NAME = "localhost"
DATABASE_NAME = "QuanLyKhuTro"
 
# Dùng Windows Authentication (Trusted_Connection) thay vì user sa/mật khẩu
DB_URL = (
    f"mssql+pyodbc://{SERVER_NAME}/{DATABASE_NAME}"
    f"?driver=SQL+Server&trusted_connection=yes"
)
 
engine = create_engine(DB_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
 
 
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
 