import unittest


class TestStudy(unittest.TestCase):
    def test_1(self):
        self.assertEqual(2, 1 + 1)

    def test_2(self):
        self.assertTrue('hello')


if __name__ == '__main__':
    unittest.main()
