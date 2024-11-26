import sqlite3
import tkinter as tk
from tkinter import messagebox

# 데이터베이스 초기화
def init_database():
    conn = sqlite3.connect('career_assist.db')
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_name TEXT,
        min_gpa REAL,
        required_certifications TEXT,
        required_language_score TEXT
    )
    """)
    
    cursor.execute("DELETE FROM jobs")  # 데이터 초기화
    sample_jobs = [
        ("데이터 분석가", 3.5, "ADsP", "TOEIC 800"),
        ("BI 분석가", 3.4, "SQL", "TOEIC 750"),
        ("생산관리자", 3.0, "ERP", "TOEIC 700"),
        ("품질관리자", 3.2, "품질관리기사", "TOEIC 750"),
        ("백엔드 개발자", 3.3, "Python, Django", "TOEIC 700"),
        ("프론트엔드 개발자", 3.2, "JavaScript, React", "TOEIC 750")
    ]
    cursor.executemany("""
    INSERT INTO jobs (job_name, min_gpa, required_certifications, required_language_score)
    VALUES (?, ?, ?, ?)
    """, sample_jobs)
    conn.commit()
    conn.close()

# GUI 초기화
def init_gui():
    def on_submit():
        name = entry_name.get()
        gpa = float(entry_gpa.get())
        certifications = entry_certifications.get().split(",")
        language_score = entry_language.get()
        interests = entry_interests.get().split(",")

        recommended_jobs = recommend_jobs(interests)
        if not recommended_jobs:
            messagebox.showinfo("추천 결과", "추천 직업이 없습니다.")
        else:
            job_list.delete(0, tk.END)
            for job in recommended_jobs:
                job_list.insert(tk.END, job)

        diagnose_preparation(gpa, certifications, language_score, recommended_jobs)

    def recommend_jobs(interests):
        conn = sqlite3.connect('career_assist.db')
        cursor = conn.cursor()
        recommended = []
        for interest in interests:
            cursor.execute("SELECT job_name FROM jobs WHERE job_name LIKE ?", (f"%{interest.strip()}%",))
            results = cursor.fetchall()
            recommended.extend([job[0] for job in results])
        conn.close()
        return recommended

    def diagnose_preparation(gpa, certifications, language_score, jobs):
        conn = sqlite3.connect('career_assist.db')
        cursor = conn.cursor()
        diagnosis_text.delete("1.0", tk.END)
        for job in jobs:
            cursor.execute("""
            SELECT min_gpa, required_certifications, required_language_score
            FROM jobs WHERE job_name = ?
            """, (job,))
            result = cursor.fetchone()
            if result:
                min_gpa, req_cert, req_lang = result
                diagnosis_text.insert(tk.END, f"\n{job} 진단 결과:\n")
                if gpa < min_gpa:
                    diagnosis_text.insert(tk.END, f"- 학점이 부족합니다. 최소 {min_gpa} 이상 필요합니다.\n")
                if req_cert not in certifications:
                    diagnosis_text.insert(tk.END, f"- 자격증이 부족합니다. 필요한 자격증: {req_cert}\n")
                if req_lang not in language_score:
                    diagnosis_text.insert(tk.END, f"- 어학 성적이 부족합니다. 최소 {req_lang} 필요합니다.\n")
            else:
                diagnosis_text.insert(tk.END, f"\n{job}에 대한 데이터가 없습니다.\n")
        conn.close()

    # Tkinter GUI 창 구성
    window = tk.Tk()
    window.title("취업 진로 지원 프로그램")
    window.geometry("800x600")

    # 레이블 추가
    main_label = tk.Label(window, text="안녕하세요! Tkinter GUI입니다.")
    main_label.pack(pady=10)

    # 버튼 클릭 함수
    def on_button_click():
        main_label.config(text="버튼이 눌렸습니다!")

    # 버튼 추가
    button = tk.Button(window, text="클릭하세요", command=on_button_click)
    button.pack(pady=10)

    tk.Label(window, text="이름:").place(x=20, y=100)
    entry_name = tk.Entry(window, width=30)
    entry_name.place(x=150, y=100)

    tk.Label(window, text="학점 (4.5 만점):").place(x=20, y=130)
    entry_gpa = tk.Entry(window, width=30)
    entry_gpa.place(x=150, y=130)

    tk.Label(window, text="취득 자격증 (쉼표로 구분):").place(x=20, y=160)
    entry_certifications = tk.Entry(window, width=30)
    entry_certifications.place(x=150, y=160)

    tk.Label(window, text="어학 성적:").place(x=20, y=190)
    entry_language = tk.Entry(window, width=30)
    entry_language.place(x=150, y=190)

    tk.Label(window, text="관심 분야 (쉼표로 구분):").place(x=20, y=220)
    entry_interests = tk.Entry(window, width=30)
    entry_interests.place(x=150, y=220)

    tk.Button(window, text="제출", command=on_submit).place(x=150, y=250)

    tk.Label(window, text="추천 직업 목록:").place(x=20, y=300)
    job_list = tk.Listbox(window, width=50, height=10)
    job_list.place(x=150, y=300)

    tk.Label(window, text="진단 결과:").place(x=20, y=480)
    diagnosis_text = tk.Text(window, width=50, height=5)
    diagnosis_text.place(x=150, y=480)

    window.mainloop()

# 실행
if __name__ == "__main__":
    init_database()
    init_gui()
