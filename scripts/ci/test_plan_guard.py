import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location("guard", pathlib.Path(__file__).with_name("guard-plan.py"))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)

class PlanGuardTests(unittest.TestCase):
    def plan(self, address, actions):
        return {"resource_changes": [{"address": address, "change": {"actions": actions}}]}

    def test_database_replacement_is_blocked(self):
        self.assertTrue(guard.check(self.plan("module.database.aws_db_instance.this", ["delete", "create"]), "apply"))

    def test_expected_image_source_replacement_is_allowed(self):
        self.assertFalse(guard.check(self.plan("module.ec2.aws_instance.this", ["delete", "create"]), "apply"))

    def test_image_source_removal_without_replacement_is_blocked(self):
        self.assertTrue(guard.check(self.plan("module.ec2.aws_instance.this", ["delete"]), "rollback"))

    def test_explicit_destroy_is_allowed(self):
        self.assertFalse(guard.check(self.plan("module.database.aws_db_instance.this", ["delete"]), "destroy"))

if __name__ == "__main__":
    unittest.main()
