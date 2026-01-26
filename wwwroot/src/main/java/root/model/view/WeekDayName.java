package root.model.view;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum WeekDayName {
    LUNDI("lundi", "lun."),
    MARDI("mardi", "mar."),
    MERCREDI("mercredi", "mer."),
    JEUDI("jeudi", "jeu."),
    VENDREDI("vendredi", "ven."),
    SAMEDI("samedi", "sam."),
    DIMANCHE("dimanche", "dim.");

    private final String fullName;
    private final String shortName;
}