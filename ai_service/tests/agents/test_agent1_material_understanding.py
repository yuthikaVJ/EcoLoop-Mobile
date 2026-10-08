"""Agent 1 - Material Understanding (app/agents/material_understanding.py).

Turns a marketplace post into a normalized material profile. The LLM names the
material; quantity, unit and post type always come from the database."""

from app.agents import MaterialUnderstandingAgent
from app.schemas import MaterialProfileLlm, PostType

from ..fakes import ScriptedLlm, post


def llm_answer(material="PET plastic bottles", ambiguous=False, reason=None):
    return ScriptedLlm(answers={MaterialProfileLlm: MaterialProfileLlm(
        material=material, materialFamily="PET plastic", form="bottles",
        isAmbiguous=ambiguous, ambiguityReason=reason)})


def test_normalizes_the_material_named_in_the_post():
    profile, call = MaterialUnderstandingAgent(llm_answer()).run(post("p1", PostType.I_HAVE, "500 kg PET bottles"))

    assert profile.material == "PET plastic bottles"
    assert profile.materialFamily == "PET plastic"
    assert profile.form == "bottles"
    assert profile.isAmbiguous is False
    assert call.model == "scripted"


def test_quantity_unit_and_type_come_from_the_database_not_the_llm():
    profile, _ = MaterialUnderstandingAgent(llm_answer()).run(
        post("p1", PostType.I_NEED, "PET", quantity="1,200", unit="Tons"))

    assert profile.quantity == 1200.0
    assert profile.unit == "t"
    assert profile.postType == PostType.I_NEED


def test_unparsable_quantity_and_unknown_unit_are_marked_unknown():
    profile, _ = MaterialUnderstandingAgent(llm_answer()).run(
        post("p1", PostType.I_HAVE, "PET", quantity="about fifty", unit="sacks"))

    assert profile.quantity is None
    assert profile.unit == "unknown"


def test_passes_on_the_llm_ambiguity_flag_and_reason():
    profile, _ = MaterialUnderstandingAgent(llm_answer(material="Unknown", ambiguous=True, reason="Material not stated.")).run(
        post("p1", PostType.I_HAVE, "Stuff for sale"))

    assert profile.isAmbiguous is True
    assert profile.ambiguityReason == "Material not stated."


def test_blank_material_is_treated_as_ambiguous():
    profile, _ = MaterialUnderstandingAgent(llm_answer(material="   ")).run(post("p1", PostType.I_HAVE, "???"))

    assert profile.isAmbiguous is True
    assert profile.ambiguityReason == "The material could not be identified."


def test_sends_only_material_fields_inside_untrusted_tags():
    llm = llm_answer()
    MaterialUnderstandingAgent(llm).run(post("p1", PostType.I_HAVE, "PET bottles", description="Clean, baled.",
                                             location="11/214 Dunuwangiya Road"))

    _, prompt, schema = llm.structured_calls[0]
    assert schema is MaterialProfileLlm
    assert "<untrusted_post>" in prompt and "Clean, baled." in prompt
    # Location, quantity and contact-type data are not needed to name a material.
    assert "Dunuwangiya" not in prompt


def test_uses_no_tools():
    assert MaterialUnderstandingAgent.tools == []
