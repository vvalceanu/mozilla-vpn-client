/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef LOTTIEPRIVATEWINDOW_H
#define LOTTIEPRIVATEWINDOW_H

#include <QJSValue>
#include <QObject>
#include <QMap>

class LottiePrivate;
class QQuickItem;
class QTimer;

// A simple "DOM window" implementation
class LottiePrivateWindow final : public QObject {
  Q_OBJECT
  Q_PROPERTY(QJSValue lottie READ lottie WRITE setLottie NOTIFY lottieChanged)

 public:
  explicit LottiePrivateWindow(LottiePrivate* parent);

  Q_INVOKABLE int setInterval(QJSValue callback, int interval) {
    return setIntervalOrTimeout(callback, interval, true);
  }

  Q_INVOKABLE void clearInterval(int id);
  Q_INVOKABLE int setTimeout(QJSValue callback, int interval) {
    return setIntervalOrTimeout(callback, interval, false);
  }

  Q_INVOKABLE void clearTimeout(int id) { return clearInterval(id); }

  Q_INVOKABLE QJSValue requestAnimationFrame(QJSValue callback);
  Q_INVOKABLE QJSValue cancelAnimationFrame(int id);

  QJSValue lottie() const;
  void setLottie(QJSValue lottie);

 signals:
  void lottieChanged();

 private:
  int setIntervalOrTimeout(QJSValue callback, int interval, bool singleShot);

 private:
  LottiePrivate* m_private = nullptr;

  struct TimerData {
    TimerData() = default;

    TimerData(QTimer* timer, QJSValue callback, int timerId, bool singleShot)
        : m_timer(timer),
          m_callback(callback),
          m_timerId(timerId),
          m_singleShot(singleShot) {}

    QTimer* m_timer = nullptr;
    QJSValue m_callback;
    int m_timerId = 0;
    bool m_singleShot = true;
  };

  int m_timerId = 0;
  QMap<int, TimerData> m_timers;
};

#endif  // LOTTIEPRIVATEWINDOW_H
