import localUnitTest from './LocalUnit.test';
import formatTest from './Format.test';

export default function testsuite() {
  localUnitTest();
  formatTest();
}
