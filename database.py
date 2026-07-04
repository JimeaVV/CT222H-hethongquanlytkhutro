from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker


SERVER_NAME = "LAPTOP-NVBANTU4\\SQLEXPRESS"
DATABASE_NAME = "QuanLyKhuTro"


DB_URL = f"mssql+pyodbc://sa:sa2016@{SERVER_NAME}/{DATABASE_NAME}?driver=SQL+Server"
engine = create_engine(DB_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()