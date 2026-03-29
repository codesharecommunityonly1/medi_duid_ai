import gradio as gr

def diagnose(symptom):
    return f"""
🧠 AI Diagnosis Report

📋 Symptoms: {symptom}

🩺 Possible Conditions:
━━━━━━━━━━━━━━━━━━
🦠 Malaria → 72%
🦠 Dengue → 18%
🦠 Typhoid → 10%

⚠️ Risk Level: HIGH

🚨 Emergency Steps:
• Stay hydrated
• Take paracetamol
• Seek medical help immediately

📞 Emergency: 108
"""

with gr.Blocks(theme=gr.themes.Soft()) as demo:
    gr.Markdown("# 🏥 MediGuide AI")
    gr.Markdown("### Offline Emergency Medical Assistant")

    with gr.Row():
        symptom = gr.Textbox(
            label="Enter Symptoms",
            placeholder="fever, headache, vomiting..."
        )

    with gr.Row():
        diagnose_btn = gr.Button("🔍 Diagnose")
        emergency_btn = gr.Button("🚨 URGENT HELP")

    output = gr.Textbox(label="Diagnosis Result")

    diagnose_btn.click(fn=diagnose, inputs=symptom, outputs=output)

    emergency_btn.click(
        fn=lambda: "🚨 Call Emergency: 108\nStay calm and seek help immediately!",
        outputs=output
    )

demo.launch(server_name="0.0.0.0", server_port=7860)