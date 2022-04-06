package ptbm.models

import blang.types.Index

class Utils {
  
  // from blogobayes
  def static boolean isControl(Index<String> index) {
    switch (index.key) {
      case "control" : true
      case "vaccinated" : false
      default : throw new RuntimeException
    }
  }
}