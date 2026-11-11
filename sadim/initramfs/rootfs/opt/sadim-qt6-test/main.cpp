#include <QApplication>
#include <QLabel>
#include <QVBoxLayout>
#include <QWidget>
#include <QPushButton>
#include <QLineEdit>
#include <QTextEdit>
#include <QFontDatabase>
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // تعيين خط يدعم العربية (FreeType + HarfBuzz عبر fontconfig)
    QFont font("DejaVu Sans", 12);
    app.setFont(font);

    // نافذة رئيسية
    QWidget window;
    window.setWindowTitle("Sadim OS — Qt6 Arabic RTL Test");
    window.resize(600, 400);

    QVBoxLayout *layout = new QVBoxLayout(&window);

    // عنوان بالعربية
    QLabel *title = new QLabel("🌌 Sadim OS — اختبار Qt6 مع دعم RTL العربي");
    title->setAlignment(Qt::AlignCenter);
    title->setStyleSheet("font-size: 18px; font-weight: bold; color: #003366; padding: 10px;");
    layout->addWidget(title);

    // نص RTL عربي
    QLabel *arabicText = new QLabel(
        "هذا نص باللغة العربية<br/>"
        "يختبر دعم RTL في Qt6 على Sadim OS<br/>"
        "مع HarfBuzz + FriBiDi + FreeType عبر fontconfig"
    );
    arabicText->setAlignment(Qt::AlignRight | Qt::AlignTop);
    arabicText->setStyleSheet("font-size: 14px; color: #333; padding: 10px; background: #f0f0f0; border-radius: 5px;");
    arabicText->setWordWrap(true);
    layout->addWidget(arabicText);

    // حقل إدخال يدعم RTL
    QLineEdit *input = new QLineEdit();
    input->setPlaceholderText("اكتب بالعربية أو الإنجليزية... (RTL مدعوم)");
    input->setLayoutDirection(Qt::RightToLeft);
    input->setStyleSheet("font-size: 14px; padding: 8px;");
    layout->addWidget(input);

    // منطقة نص متعددة الأسطر
    QTextEdit *textEdit = new QTextEdit();
    textEdit->setPlaceholderText("منطقة نص RTL...\nيدعم التنسيق والفقرات");
    textEdit->setLayoutDirection(Qt::RightToLeft);
    textEdit->setStyleSheet("font-size: 13px; padding: 8px;");
    layout->addWidget(textEdit);

    // زر اختبار
    QPushButton *btn = new QPushButton("✅ اختبار RTL — اطبع المحتوى في الطرفية");
    btn->setStyleSheet("font-size: 14px; padding: 10px; background: #003366; color: white; border-radius: 5px;");
    QObject::connect(btn, &QPushButton::clicked, [&]() {
        qDebug() << "=== Sadim Qt6 RTL Test ===";
        qDebug() << "Input:" << input->text();
        qDebug() << "TextEdit:" << textEdit->toPlainText();
        qDebug() << "Layout direction:" << (app.layoutDirection() == Qt::RightToLeft ? "RTL" : "LTR");
    });
    layout->addWidget(btn);

    // معلومات النظام
    QLabel *info = new QLabel(
        QString("Qt Version: %1 | Platform: %2 | Font: %3")
            .arg(qVersion())
            .arg(QGuiApplication::platformName())
            .arg(font.family())
    );
    info->setAlignment(Qt::AlignCenter);
    info->setStyleSheet("font-size: 11px; color: #666; padding: 10px;");
    layout->addWidget(info);

    window.show();
    return app.exec();
}