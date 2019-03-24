var minDate = new Date(2012, 0, 1, 0, 0, 0, 0);
var maxDate = new Date(2013, 0, 1, 0, 0, 0, 0);
var delta = maxDate.getTime() - minDate.getTime();

var job_id = arg2;

var documentNumber = arg1;
var batchNumber = 5 * 1000;

var job_name = 'Job#' + job_id
var start = new Date();

var batchDocuments = new Array();
var index = 0;

while (index < documentNumber) {
    var date = new Date(minDate.getTime() + Math.random() * delta);

    var document = {
        "_id": UUID(),
        "based_on": null,
        "body_site": {
            "coding": [
                {
                    "code": "1341001:272741003=7771000",
                    "system": "eHealth/body_sites"
                }
            ],
            "text": null
        },
        "categories": [
            {
                "coding": [
                    {
                        "code": "vital_signs",
                        "system": "eHealth/observation_categories"
                    }
                ],
                "text": null
            }
        ],
        "code": {
            "coding": [
                {
                    "code": "10569-2",
                    "system": "eHealth/observations_codes"
                }
            ],
            "text": null
        },
        "comment": "Some comment",
        "components": [
            {
                "code": {
                    "coding": [
                        {
                            "code": "PRT-10",
                            "system": "eHealth/observations_codes"
                        }
                    ],
                    "text": null
                },
                "interpretation": {
                    "coding": [
                        {
                            "code": "L",
                            "system": "eHealth/observation_interpretations"
                        }
                    ],
                    "text": null
                },
                "reference_ranges": [
                    {
                        "age": {
                            "high": {
                                "comparator": "<",
                                "unit": "years",
                                "value": 35
                            },
                            "low": {
                                "comparator": ">",
                                "unit": "years",
                                "value": 18
                            }
                        },
                        "applies_to": [
                            {
                                "coding": [
                                    {
                                        "code": "male",
                                        "system": "eHealth/reference_range_applications"
                                    }
                                ],
                                "text": null
                            }
                        ],
                        "high": {
                            "code": "mg",
                            "comparator": "<",
                            "system": "eHealth/units",
                            "unit": "mg",
                            "value": 27
                        },
                        "low": {
                            "code": "mg",
                            "comparator": ">",
                            "system": "eHealth/units",
                            "unit": "mg",
                            "value": 13
                        },
                        "text": "Some text",
                        "type": {
                            "coding": [
                                {
                                    "code": "normal",
                                    "system": "eHealth/reference_range_types"
                                }
                            ],
                            "text": null
                        }
                    }
                ],
                "value": {
                    "type": "quantity",
                    "value": {
                        "code": "mg",
                        "comparator": ">",
                        "system": "eHealth/units",
                        "unit": "mg",
                        "value": 13
                    }
                }
            }
        ],
        "context": {
            "display_value": null,
            "identifier": {
                "type": {
                    "coding": [
                        {
                            "code": "encounter",
                            "system": "eHealth/resources"
                        }
                    ],
                    "text": null
                },
                "value": UUID()
            }
        },
        "effective_at": {
            "type": "effective_date_time",
            "value": date,
        },
        "inserted_at": date,
        "inserted_by": UUID(),
        "interpretation": {
            "coding": [
                {
                    "code": "L",
                    "system": "eHealth/observation_interpretations"
                }
            ],
            "text": null
        },
        "issued": date,
        "method": {
            "coding": [
                {
                    "code": "255459008",
                    "system": "eHealth/observation_methods"
                }
            ]
        },
        "patient_id": UUID(),
        "primary_source": true,
        "reference_ranges": [
            {
                "age": {
                    "high": {
                        "comparator": "<",
                        "unit": "years",
                        "value": 35
                    },
                    "low": {
                        "comparator": ">",
                        "unit": "years",
                        "value": 18
                    }
                },
                "applies_to": [
                    {
                        "coding": [
                            {
                                "code": "male",
                                "system": "eHealth/reference_range_applications"
                            }
                        ],
                        "text": null
                    }
                ],
                "high": {
                    "code": "mg",
                    "comparator": "<",
                    "system": "eHealth/units",
                    "unit": "mg",
                    "value": 27
                },
                "low": {
                    "code": "mg",
                    "comparator": ">",
                    "system": "eHealth/units",
                    "unit": "mg",
                    "value": 13
                },
                "text": "Some text",
                "type": {
                    "coding": [
                        {
                            "code": "normal",
                            "system": "eHealth/reference_range_types"
                        }
                    ],
                    "text": null
                }
            }
        ],
        "source": {
            "type": "performer",
            "value": {
                "display_value": null,
                "identifier": {
                    "type": {
                        "coding": [
                            {
                                "code": "employee",
                                "system": "eHealth/resources"
                            }
                        ],
                        "text": null
                    },
                    "value": UUID(),
                }
            }
        },
        "status": "valid",
        "updated_at": date,
        "updated_by": UUID(),
        "value": {
            "type": "quantity",
            "value": {
                "code": "mg",
                "comparator": ">",
                "system": "eHealth/units",
                "unit": "mg",
                "value": 13
            }
        }
    }

    batchDocuments[index % batchNumber] = document;
    if ((index + 1) % batchNumber == 0) {
        db.randomData.insert(batchDocuments);
    }
    index++;
    if (index % 100000 == 0) {
        print(job_name + ' inserted ' + index + ' documents.');
    }
}
print(job_name + ' inserted ' + documentNumber + ' in ' + (new Date() - start) / 1000.0 + 's');


