package root.model.view;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum MonthName {

    JANVIER("janvier", "janv."),
    FEVRIER("février", "févr."),
    MARS("mars", "mars"),
    AVRIL("avril", "avr."),
    MAI("mai", "mai"),
    JUIN("juin", "juin"),
    JUILLET("juillet", "juil."),
    AOUT("août", "août"),
    SEPTEMBRE("septembre", "sept."),
    OCTOBRE("octobre", "oct."),
    NOVEMBRE("novembre", "nov."),
    DECEMBRE("décembre", "déc.");

    private final String fullName;
    private final String shortName;
}
