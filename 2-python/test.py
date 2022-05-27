import sys
from PyQt5 import *
from PyQt5.QtWidgets import QApplication, QCalendarWidget, QWidget, QLabel
from PyQt5.QtCore import *
from PyQt5.QtGui import *

class Example(QWidget):
   def __init__(self):
      super(Example, self).__init__()
      self.initUI()
   def initUI(self):
      my_calendar = QCalendarWidget(self)
      my_calendar.setGridVisible(True)
      my_calendar.move(10, 20)
      my_calendar.clicked[QDate].connect(self.show_date)
      self.my_label = QLabel(self)
      date = my_calendar.selectedDate()
      self.my_label.setText(date.toString())
      self.my_label.move(10, 220)
      self.setGeometry(100,100,320,270)
      self.setWindowTitle('Calendar')
      self.show()
   def show_date(self, date):
      self.my_label.setText(date.toString())

def main():
   app = QApplication(sys.argv)
   ex = Example()
   sys.exit(app.exec_())
if __name__ == '__main__':
   main()