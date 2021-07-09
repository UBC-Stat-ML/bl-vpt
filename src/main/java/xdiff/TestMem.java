package xdiff;

public class TestMem
{
  public static void main(String [] args) {
    
    int size = 1;
    
    for (int i = 0; i < 30; i++) {
      System.out.println("size: " + size);
      final int currentsize = size;
      double mean = Weird.bench(100, () -> playWithArray(currentsize));
      System.out.println("\tThroughput: " + (currentsize / mean));
      size *= 2.0;
    }
  }
  
  public static void playWithArray(int size) {
    final double [] array = new double[size];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < array.length; j++) {
        array[j] = 2.0 * (array[size - j - 1]);
      }
    }
  }
}
