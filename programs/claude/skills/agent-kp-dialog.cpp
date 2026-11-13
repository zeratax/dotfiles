// agent-kp's approval dialog. Shows the rich text on stdin (built and escaped
// by agent-kp) and prints the answer: once, <HOURS>h or deny. No answer, or
// anything else, means the dialog failed, not that Jona denied.
#include <QApplication>
#include <QFile>
#include <QMessageBox>
#include <QPushButton>
#include <cstdio>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    bool ok = false;
    const int hours = argc == 2 ? QString::fromLocal8Bit(argv[1]).toInt(&ok) : 0;
    QFile in;
    if (!ok || hours <= 0 || !in.open(stdin, QIODevice::ReadOnly)) {
        std::fputs("usage: agent-kp-dialog HOURS < text.html\n", stderr);
        return 2;
    }

    QMessageBox box(QMessageBox::Warning, "Agent requests a KeePass password",
                    QString::fromUtf8(in.readAll()));
    box.setTextFormat(Qt::RichText);
    auto *once = box.addButton("Allow once", QMessageBox::YesRole);
    auto *timed = box.addButton(QString("Allow for %1 h").arg(hours),
                                QMessageBox::AcceptRole);
    auto *deny = box.addButton("Deny", QMessageBox::RejectRole);
    box.setDefaultButton(deny);
    box.setEscapeButton(deny);
    box.exec();

    // closing the window counts as Escape, i.e. Deny
    const auto *clicked = box.clickedButton();
    if (clicked == once)
        std::puts("once");
    else if (clicked == timed)
        std::printf("%dh\n", hours);
    else
        std::puts("deny");
    return 0;
}
