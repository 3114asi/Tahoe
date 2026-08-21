// kvantum-dialog-alpha-fix: forces QDialog windows onto an alpha-capable
// native surface even when something realizes their native window before
// Kvantum's style polish() runs.
//
// Root cause (found by reading Kvantum's style/polishing.cpp): Kvantum gives
// a top-level window real per-pixel background alpha (background painted
// translucent, text/icons stay fully opaque -- what makes Dolphin's own main
// window look like glass) by setting Qt::WA_TranslucentBackground *before*
// the window's native surface is created. If the surface already exists by
// the time polish() runs (Qt::WA_WState_Created already set), Kvantum gives
// up permanently: `window->format().alphaBufferSize() != 8` -> the window
// stays fully opaque forever, and only a compositor-wide KWin opacity rule
// can add transparency afterwards -- which multiplies the *whole* rendered
// texture, blurring/dimming icons and text along with the background.
//
// QDialog windows used by Dolphin/KIO (e.g. the "Properties" dialog) call
// QWidget::winId() during construction -- to be able to set up the
// transient-for parent relationship -- well before Kvantum's polish() ever
// sees them. QMenu popups don't do this, which is why menus already render
// with correct background-only translucency and dialogs don't.
//
// Fix: interpose QWidget::winId() and, for QDialog windows not yet created,
// set WA_TranslucentBackground/WA_NoSystemBackground first -- exactly what
// Kvantum's own polish() would do anyway, just early enough to matter.
// Verified in isolation: a QDialog that calls winId() before show() gets
// alphaBufferSize()==0 (opaque) unmodified, ==8 (translucent-capable) with
// this interposer preloaded.

#include <QDialog>
#include <QWidget>
#include <dlfcn.h>

using WinIdFn = quintptr (*)(const QWidget *);

extern "C" quintptr _ZNK7QWidget5winIdEv(const QWidget *self)
{
    static WinIdFn real = reinterpret_cast<WinIdFn>(
        dlsym(RTLD_NEXT, "_ZNK7QWidget5winIdEv"));

    QWidget *w = const_cast<QWidget *>(self);
    if (!w->testAttribute(Qt::WA_WState_Created)
        && w->isWindow()
        && qobject_cast<QDialog *>(w))
    {
        w->setAttribute(Qt::WA_TranslucentBackground);
        w->setAttribute(Qt::WA_NoSystemBackground);
    }

    return real(self);
}
