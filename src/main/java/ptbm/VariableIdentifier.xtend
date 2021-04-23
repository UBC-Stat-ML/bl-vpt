package ptbm

import org.eclipse.xtend.lib.annotations.Data

@Data
class VariableIdentifier {
  /*
   * Exploit the asymmetry between cloning and 
   * the first time the object is created. 
   * 
   * When first created, a unique id will be created
   * When cloning this string will be copied from the original.
   */
  val id = Integer.toHexString(super.hashCode())
  
  override toString() { id }
}